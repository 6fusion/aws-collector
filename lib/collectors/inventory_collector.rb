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
      hosts: instances.map { |instance| host_model(instance) }
    )

    puts "Saving the inventory into DB..."
    inventory.save!
  end

  private

  def host_model(instance)
    type = instance.instance_type
    tags = tags_to_map(instance.tags).to_dot
    hardware = INSTANCE_TYPES[type].to_dot

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
      nics: instance.network_interfaces.map { |network| nic_model(network) },
      volumes: instance.volumes.map { |volume| volume_model(volume) }
    )
  end

  def nic_model(network)
    Nic.new(
      custom_id: network.id,
      description: network.description,
      status: network.status
    )
  end

  def volume_model(volume)
    tags = tags_to_map(volume.tags)
    Volume.new(
      custom_id: volume.id,
      name: tags["Name"],
      type: volume.volume_type,
      size_gib: volume.size,
      iops: volume.iops,
      state: volume.state,
      tags: tags
    )
  end

  def instances
    regions = aws_client_ec2.describe_regions.data.regions.map(&:region_name)
    regions.collect do |region|
      aws_ec2_resource(region).instances.entries
    end.compact.flatten
  end

  def tags_to_map(tags)
    Hash[ tags.map { |tag| [tag.key, tag.value] } ]
  end
end