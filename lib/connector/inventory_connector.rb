class InventoryConnector
  def initialize
    @meter_client = MeterHttpClient.new
    @organization_id = PropertyHelper.organization_id
    @infrastructure_id = AWSHelper::Clients.iam_userid
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

  def create_host(host)
    payload = host.to_payload
    @meter_client.create_machine(@infrastructure_id, payload)
  end

  def delete_host(machine_id, payload)
    payload[:status] = :deleted
    @meter_client.update_machine(machine_id, payload)
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
