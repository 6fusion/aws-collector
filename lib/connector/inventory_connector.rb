class InventoryConnector
  def initialize
    @meter_client = MeterHttpClient.new
    @organization_id = PropertyHelper.organization_id
    @infrastructure_id = PropertyHelper.infrastructure_id
  end

  def check_organization_exist
    exist = @meter_client.get_organization(@organization_id).success?
    exist || raise("Organization with ID [#{@organization_id}] does not exist. Please, create")
  end

  def send_infrastructure(inventory)
    puts "Sending inventory to meter..."
    send("Failed to send post_infrastructure with ID #{@organization_id}. Inventory: #{inventory}") do
      @meter_client.post_infrastructure(inventory.infrastructure_json, @organization_id)
    end
    puts "Inventory sent"
  end

  def send_host(host)
    puts "Sending host [#{host.custom_id}]..."
    payload = host.to_payload
    send("Failed to send machine. Infrastructure ID: #{@infrastructure_id}. Payload: #{payload}") do
      @meter_client.post_machine(@infrastructure_id, payload)
    end
    puts "Host sent"
  end

  private

  def send(error_msg)
    response = yield
    response.success? || raise("#{error_msg}\n\nResponse: #{response}")
  end
end
