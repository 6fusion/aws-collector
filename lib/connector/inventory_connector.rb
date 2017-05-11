require 'logger'

STDOUT.sync = true

class InventoryConnector
  def initialize
    @meter_client = MeterHttpClient.new
    @organization_id = PropertyHelper.organization_id
    @infrastructure_id = AWSHelper::Identity::account_id
    @logger = ::Logger.new(STDOUT)
    @logger.level = ENV['LOG_LEVEL'] || 'info'
  end

  def check_organization_exist
    exist = @meter_client.get_organization(@organization_id).success?
    exist || raise("Organization with ID [#{@organization_id}] does not exist. Please, create")
  end

  def send_infrastructure(inventory)
    payload = inventory.infrastructure_json
    if infrastructure_exist?
      @meter_client.update_infrastructure(payload, @infrastructure_id)
    else
      @meter_client.post_infrastructure(payload, @organization_id)
    end
  end

  def get_machine(host)
    @meter_client.get_machine(host.custom_id)
  end

  def create_host(host)
    payload = host.to_payload
    # If name tag is missing, set name to custom_id (aka instance ID)
    payload[:name] ||= payload[:custom_id]
    # if payload[:name].nil? or payload[:name].empty?
    #   payload[:name] = payload[:custom_id]
    # end
    @meter_client.create_machine(@infrastructure_id, payload)
  end

  def delete_host(machine_id, payload)
    payload[:status] = :deleted
    patch_host(machine_id, payload)
  end

  def patch_host(machine_id, payload)
    payload.delete(:disks)
    payload.delete(:nics)
    # Do not update machine names to be "blank"
    if payload[:name].empty?
      payload.delete(:name)
    end
    @meter_client.update_machine(machine_id, payload)
  end

  def create_disk(machine_id, disk)
    payload = disk.to_payload
    @meter_client.create_disk(machine_id, payload)
  end

  def delete_disk(disk_id, payload)
    payload[:status] = :deleted
    patch_disk(disk_id, payload)
  end

  def patch_disk(disk_id, payload)
    @meter_client.update_disk(disk_id, payload)
  end

  def create_nic(machine_id, nic)
    payload = nic.to_payload
    @meter_client.create_nic(machine_id, payload)
  end

  def delete_nic(nic_id, payload)
    payload[:status] = :deleted
    patch_nic(nic_id, payload)
  end

  def patch_nic(nic_id, payload)
    @meter_client.update_nic(nic_id, payload)
  end

  def infrastructure_exist?
    infrastructure.success?
  end

  def infrastructure_json
    response = infrastructure
    return unless response.success?
    JSON.parse(response.body)
  end

  def infrastructure
    @meter_client.get_infrastructure(@infrastructure_id)
  end
end
