class MetricsSender

  def send
    samples = Sample.all.map { |sample| sample.to_payload }
    return if samples.empty?

    puts "Sending samples to meter"
    response = MeterHttpClient.new.samples(samples)
    if response.code == 204
      puts "Samples have been sent, updating last sent time, destroying samples in Mongo"
      update_last_sent_time
      Sample.destroy_all
    else
      puts "Error occurred during sending samples to meter. Status: #{response.code}"
    end
  end

  private
  def update_last_sent_time
    end_time = last_sample_time
    puts "Updating last sent metrics time to #{end_time}"

    synced_inventory = synced_inventory
    return if !synced_inventory

    synced_inventory.hosts.update_all(last_sent_metrics_time: end_time)
    response = InventoryConnector.new.send_infrastructure(synced_inventory)

    if response.code != 200
      puts "Error occurred during updating last sent time for infrastructure id '#{inventory.custom_id}'"
    end
  end

  def last_sample_time
    Sample.order_by(:end_time => :desc).limit(1).first.end_time
  end

  def synced_inventory
    Inventory.where(synchronized: true).first
  end
end
