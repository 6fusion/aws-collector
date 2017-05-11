
STDOUT.sync = true

class MetricsSender

  def send

    Sample.all.each_slice(100) do |batch|
      samples = batch.map {|sample| sample.to_payload }
      return if samples.empty?

      $logger.info "Sending samples to meter"
      response = MeterHttpClient.new.samples(samples)
      if response.code == 204
        $logger.info "Samples have been sent, updating last sent time, destroying samples in Mongo"
        update_last_sent_time
        Sample.destroy_all
      else
        $logger.error "Error occurred during sending samples to meter. Status: #{response.code}"
      end
    end

  end

  private
  def update_last_sent_time
    end_time = last_sample_time
    $logger.info "Updating last sent metrics time to #{end_time}"

    inventory = synced_inventory
    return unless inventory

    inventory.hosts.update_all(last_sent_metrics_time: end_time)
    response = InventoryConnector.new.send_infrastructure(inventory)

    if response.code != 200
      $logger.error "Error occurred during updating last sent time for infrastructure id '#{inventory.custom_id}'"
    end
  end

  def last_sample_time
    Sample.order_by(:end_time => :desc).limit(1).first.end_time
  end

  def synced_inventory
    Inventory.first
  end
end
