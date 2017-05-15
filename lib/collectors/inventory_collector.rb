require 'inventory_helper'
require 'aws_helper'
require 'property_helper'
require 'logger'

class InventoryCollector
  include InventoryHelper
  include AWSHelper
  include PropertyHelper
  include AWS::PriceList
  include AWS::DetailedReport

  def initialize
    @instance_types = Hash.new
  end

  def save!(inventory)
    $logger.info { "Saving inventory into Mongo..." }
    inventory.save!
    Inventory.all.each { |inv| inv.delete if inventory != inv }
    $logger.info { "Inventory saved" }
  end

  def current_inventory
    begin
      $logger.info { "Trying to get the current inventory from MongoDB..." }
      inventory = Inventory.order_by(created_at: :desc).first
      return inventory if inventory

      # $logger.info { "Trying to get the current inventory from Meter..." }
      # inventory = InventoryConnector.new.infrastructure_json
      # return inventory.compact_recursive.symbolize_recursive if inventory

      $logger.info { "Inventory does not exist yet on meter. Using a new one..." }
      Inventory.new # new empty inventory
    end
  end

  def current_inventory_json
    begin
      $logger.info { "Trying to get the current inventory from MongoDB..." }
      inventory = Inventory.order_by(created_at: :desc).first
      return inventory.infrastructure_json if inventory

      # $logger.info { "Trying to get the current inventory from Meter..." }
      # inventory = InventoryConnector.new.infrastructure_json
      # return inventory.compact_recursive.symbolize_recursive if inventory

      $logger.info { "Inventory does not exist yet on meter. Using a new one..." }
      Inventory.new.infrastructure_json # new empty inventory
    end
  end

  def collect_inventory
    $logger.info { "Collecting the actual inventory from AWS..." }
    inventory = Inventory.new(
      hosts: instances,
      volumes: volumes,
      networks: vpcs
    )

    $logger.info { "AWS inventory was collected" }
    inventory
  end

  private

  def host_model(instance)
    type = instance.instance_type
    instance_id = instance.instance_id
    hardware = nil
    begin
      @instance_types[type] ||= InstanceType.find_by(name: type)
      hardware = @instance_types[type]
    rescue StandardError => e
      $logger.error "TYPE triggering exception: #{type}"
      $logger.error e
    end

    disks = instance.block_device_mappings.map{|device| host_disk_model(device) }
    disks << instance_disk_model(instance) if instance_disk_model(instance)

    nics = instance.network_interfaces.map { |network| network_model(network) }
    nics << instance_nic_model(instance)

    device_mappings = Hash[*instance.block_device_mappings.map do |device|
      [device.device_name, device.ebs.volume_id]
    end.flatten]

    region = availability_zone_to_region(instance.placement.availability_zone)
    platform = instance.platform.nil? ? "Linux" : "Windows"

    price_details =
      AWS::DetailedReport.price_details(instance_id) ||
      EC2.price_details(region: region,
                        instance_type: type,
                        operating_system: platform,
                        ebs_optimized: instance.ebs_optimized,
                        tenancy: instance.placement.tenancy) ||
      { cost_per_hour: 0, billing_resource: "none" }.to_dot

    # is this always safe?
    region = instance.placement.availability_zone.chop
    Host.new(
      custom_id: instance_id,
      name: name_from_tags(instance.tags),
      type: type,
      region: region,
      tags: ['platform:aws', 'type:instance', "region:#{region}"] + tags_to_array(instance.tags),
      state: instance.state.name,
      monitoring: instance.monitoring.state,
      memory_gb: hardware[:memory_gb],
      network: hardware[:network],
      platform: platform,
      cpu: Cpu.new(
        cores: hardware[:cores],
        speed_ghz: hardware[:cpu_speed_ghz]
      ),
      nics: nics,
      disks: disks,
      cost_per_hour: price_details.cost_per_hour,
      billing_resource: price_details.billing_resource,
      device_mappings: device_mappings
    )
  end

  def network_model(network)
    Nic.new(
      custom_id: network.network_interface_id,
      name: network.network_interface_id,
      state: network.status,
    )
  end

  def nic_model(vpc)
    Nic.new(
      custom_id: vpc.vpc_id,
      name: name_from_tags(vpc.tags) || vpc.vpc_id,
      state: vpc.state,
      tags: tags_to_array(vpc.tags)
    )
  end

  def disk_model(volume)
    region = availability_zone_to_region(volume.availability_zone)
    volume_type = volume.volume_type
    price_details =
      EBS.price_details(region: region, type: volume_type) ||
      { cost_per_hour: 0, billing_resource: "none" }.to_dot

    Disk.new(
      custom_id: volume.volume_id,
      name: name_from_tags(volume.tags) || volume.volume_id,
      type: volume_type,
      size_gib: volume.size,
      iops: volume.iops,
      state: volume.state,
      tags: tags_to_array(volume.tags),
      cost_per_hour: price_details.cost_per_hour,
      billing_resource: price_details.billing_resource
    )
  end

  def host_disk_model(volume)
    Disk.new(
      custom_id: volume.ebs.volume_id,
      name: volume.device_name,
      type: 'ebs',
      size_gib: 0,
      state: volume.ebs.status
    )
  end

  def instance_disk_model(instance)
    store = INSTANCE_STORES[instance.instance_type]&.to_dot
    return nil unless store

    Disk.new(
      custom_id: "united_instance_store_of_instance_#{instance.instance_id}",
      name: "United instance store",
      type: :instance_store,
      size_gib: store.size_gb * store.quantity,
      instance_store_type: store.type,
      instance_stores_count: store.quantity
    )
  end

  def instance_nic_model(instance)
    Nic.new(
      custom_id: "united_network_of_instance_#{instance.instance_id}",
      name: :united_network,
      state: :available
    )
  end

  def vpcs
    vpcs = []
    regions.each do |region|
      $logger.debug { "Collecting VPCs for #{region}" }
      response = Clients.ec2(region).describe_vpcs
      response.vpcs.each{|vpc|
        vpcs << nic_model(vpc) }
    end
    $logger.info { "#{vpcs.size} VPCs collected." }
    vpcs
  end

  def volumes
    volumes = []
    regions.each do |region|
      $logger.debug { "Collecting volumes for #{region}" }
      ec2 = Clients.ec2(region)
      token = nil
      loop do
        response = ec2.describe_volumes(next_token: token)
        response.volumes.each{|volume|
          volumes << disk_model(volume) }
        break unless response.next_token
      end
    end
    $logger.info { "#{volumes.size} volumes collected." }
    volumes
  end

  def instances
    instances = []
    count = 0
    regions.each do |region|
      $logger.debug { "Collecting instances for #{region}" }
      ec2 = Clients.ec2(region)
      region_count = 0
      token = nil
      loop do
        response = ec2.describe_instances(next_token: token)
        response.reservations.each{|reservation|
          reservation.instances.each{|instance|
            region_count += 1
            print "#{instance.instance_id} " if $logger.level == ::Logger::DEBUG
            instances << host_model(instance) } }
        token = response.next_token
        break unless token
      end
      $logger.debug { "Collected #{region_count} instances from #{region}." }
      count += region_count
    end
    $logger.info { "#{count} EC2 instances collected." }
    instances
  end

  def regions
    @regions ||= Clients.ec2.describe_regions.data.regions.map(&:region_name).sort{|a,b| a.start_with?('us-') ? -1 : (a<=>b)}
  end

  def tags_to_array(tags)
    tags.map{|tag| "#{tag.key}:#{tag.value}"}
  end
  def name_from_tags(tags)
    tags.find{|tag| tag.key.match(/\Aname\z/i)}&.value
  end

  def availability_zone_to_region(availability_zone)
    availability_zone.gsub(/[a-z]$/, "")
  end
end
