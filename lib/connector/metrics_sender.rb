class MetricsSender

  def send
    #group by sample_start  #add index

    Sample.persisted_start_times.each do |start_time|
      $logger.info "Submitting samples for #{start_time}"
      Sample.group_by_start_time(start_time)[:samples].each_slice(100) do |samples_bson|
        samples = samples_bson.map{|s| Sample.new(s)}
        response = MeterHttpClient.new.samples( samples.map(&:to_payload) )
        if response.code != 204
          $logger.error "Error occurred during sending samples to meter: #{response.code}"
          $logger.error "Error response body: #{response.body}"
        end

        # TODO cf Sample.where(id: { "$in": samples.map(&:id) } ).delete_all
        Sample.find( samples.map(&:id) ).delete_all
      end
      $logger.info "Sample submission for #{start_time} completed"
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
