require 'kubernetes_helper'

class MetricsSender
  include KubernetesHelper

  def send
    Sample.persisted_start_times.each do |start_time|
      $logger.info "Submitting samples for #{start_time}"
      Sample.group_by_start_time(start_time).each do |samples_by_date|

        pool = Concurrent::ThreadPoolExecutor.new(min_threads: 1,
                                                  max_threads: 5,
                                                  max_queue: 0,
                                                  fallback_policy: :caller_runs)

        samples_by_date[:samples].each_slice(200) do |samples_bson|
          pool.post do
            samples = samples_bson.map{|s| Sample.new(s)}
            response = MeterHttpClient.new.samples( samples.map(&:to_payload) )
            if response.code != 204
              $logger.error "Error occurred during sending samples to meter: #{response.code}"
              $logger.error "Error response body: #{response.body}"
            end

            Sample.where( id: { "$in": samples.map(&:id) } ).delete_all
            update_last_sent_time
            # delete corresponding inventory as we go?
            # most likely: this needs a queue
          end

        end

        pool.shutdown
        pool.wait_for_termination

      end
      $logger.info "Sample submission for #{start_time} completed"
    end

  end

  private
  def update_last_sent_time
    end_time = last_sample_time
    $logger.info "Updating last sent metrics time to #{end_time}"

    KubernetesHelper::save_value("lastSampleTime", end_time)
  end

  def last_sample_time
    Sample.order_by(:end_time => :desc).limit(1).first.end_time
  end

  def synced_inventory
    Inventory.first
  end
end
