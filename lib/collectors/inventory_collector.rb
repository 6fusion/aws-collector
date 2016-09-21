require 'inventory_helper'
require 'ec2_helper'
require 'property_helper'

class InventoryCollector
  include InventoryHelper
  include Ec2Helper
  include PropertyHelper

  def initialize
    PropertyHelper.init_mongo
  end

  def collect_inventory
    puts "Starting AWS inventory collector..."
    inventory = Inventory.new(
      organization_id: PropertyHelper.read_property("ORGNANIZATION_ID"),
      name: PropertyHelper.read_property("ORGNANIZATION_NAME"),
      hosts: instances.map { |instance| host_model(instance) },
      volumes: volumes.map { |volume| disk_model(volume) },
      networks: vpcs.map { |vpc| nic_model(vpc) }
    )

    puts "Saving the inventory into DB..."
    inventory.save!
  end

  private

  def host_model(instance)
    type = instance.instance_type
    tags = tags_to_map(instance.tags).to_dot
    hardware = INSTANCE_TYPES[type].to_dot

    disks = instance.volumes.map { |volume| disk_model(volume) }
    disks << instance_disk_model(instance) if instance_disk_model(instance)

    Host.new(
      custom_id: instance.instance_id,
      name: tags["Name"],
      type: type,
      region: instance.client.config.region,
      tags: tags,
      state: instance.state.name,
      launch_time: instance.launch_time,
      monitoring: instance.monitoring.state,
      memory_gb: hardware.ram_gb,
      network: hardware.network,
      platform: instance.platform,
      cpu: Cpu.new(
        cores: hardware.cores,
        speed_ghz: hardware.cpu_speed_ghz
      ),
      nics: [
        Nic.new(
          custom_id: "united_network_of_instance_#{instance.instance_id}",
          name: :united_network,
          state: :available
        )
      ],
      disks: disks
    )
  end

  def nic_model(vpc)
    tags = tags_to_map(vpc.tags)
    Nic.new(
      custom_id: vpc.id,
      name: tags["Name"],
      state: vpc.state,
      tags: tags
    )
  end

  def disk_model(volume)
    tags = tags_to_map(volume.tags)
    Disk.new(
      custom_id: volume.volume_id,
      name: tags["Name"],
      type: volume.volume_type,
      size_gib: volume.size,
      iops: volume.iops,
      state: volume.state,
      tags: tags
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
      isntance_store_type: store.type,
      isntance_stores_count: store.quantity
    )
  end

  def vpcs
    regions.collect do |region|
      aws_ec2_resource(region).vpcs.entries
    end.compact.flatten
  end

  def volumes
    regions.collect do |region|
      aws_ec2_resource(region).volumes.entries
    end.compact.flatten
  end

  def instances
    regions.collect do |region|
      aws_ec2_resource(region).instances.entries
    end.compact.flatten
  end

  def regions
    aws_client_ec2.describe_regions.data.regions.map(&:region_name)
  end

  def tags_to_map(tags)
    Hash[ tags.map { |tag| [tag.key, tag.value] } ]
  end
end