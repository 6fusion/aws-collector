require 'inventory_helper'
require 'aws_helper'
require 'property_helper'

class InventoryCollector
  include InventoryHelper
  include AWSHelper
  include PropertyHelper
  include AWS::PriceList
  include AWS::DetailedReport

  def save!(inventory)
    puts "Saving inventory into Mongo..."
    inventory.save!
    Inventory.all.each { |inv| inv.delete if inventory != inv }
    puts "Inventory saved"
  end

  def current_inventory_json
    begin
      puts "Trying to get the current inventory from MongoDB..."
      inventory = Inventory.order_by(created_at: :desc).first
      return inventory.infrastructure_json if inventory

      puts "Trying to get the current inventory from Meter..."
      inventory = InventoryConnector.new.infrastructure_json
      return inventory.compact_recursive.symbolize_recursive if inventory

      puts "Inventory does not exist yet on meter. Using a new one..."
      Inventory.new.infrastructure_json # new empty inventory
    end
  end

  def collect_inventory
    puts "Collecting the actual inventory from AWS..."
    inventory = Inventory.new(
      hosts: instances.map { |instance| host_model(instance) },
      volumes: volumes.map { |volume| disk_model(volume) },
      networks: vpcs.map { |vpc| nic_model(vpc) }
    )

    puts "AWS inventory was collected"
    inventory
  end

  private

  def host_model(instance)
    type = instance.instance_type
    instance_id = instance.instance_id
    hardware = nil
    begin
    hardware = INSTANCE_TYPES[type].to_dot
    rescue StandardError => e
      puts "TYPE triggering exception: #{type}"
      puts e
    end

    disks = instance.volumes.map { |volume| disk_model(volume) }
    disks << instance_disk_model(instance) if instance_disk_model(instance)

    nics = instance.network_interfaces.map { |network| network_model(network) }
    nics << instance_nic_model(instance)

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

    Host.new(
      custom_id: instance_id,
      name: name_from_tags(instance.tags)
      type: type,
      region: instance.client.config.region,
      tags: tags_to_array(instance.tags),
      state: instance.state.name,
      monitoring: instance.monitoring.state,
      memory_gb: hardware.ram_gb,
      network: hardware.network,
      platform: platform,
      cpu: Cpu.new(
        cores: hardware.cores,
        speed_ghz: hardware.cpu_speed_ghz
      ),
      nics: nics,
      disks: disks,
      cost_per_hour: price_details.cost_per_hour,
      billing_resource: price_details.billing_resource
    )
  end

  def network_model(network)
    Nic.new(
        custom_id: network.id,
        name: network.id,
        state: network.status,
    )
  end

  def nic_model(vpc)
    Nic.new(
      custom_id: vpc.id,
      name: name_from_tags(vpc.tags) || vpc.id,
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

  def instance_disk_model(instance)
    store = INSTANCE_STORES[instance.instance_type]&.to_dot
    return nil unless store

    Disk.new(
      custom_id: "united_instance_store_of_instance_#{instance.instance_id}",
      name: "United instance store",
      type: :instance_store,
      size_gib: store.size_gb,
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
    regions.collect do |region|
      Resources.ec2(region).vpcs.entries
    end.compact.flatten
  end

  def volumes
    regions.collect do |region|
      Resources.ec2(region).volumes.entries
    end.compact.flatten
  end

  def instances
    regions.collect do |region|
      Resources.ec2(region).instances.entries
    end.compact.flatten
  end

  def regions
    Clients.ec2.describe_regions.data.regions.map(&:region_name)
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
