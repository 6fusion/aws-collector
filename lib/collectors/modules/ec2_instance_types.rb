require 'logger'
require 'json'
require 'httparty'

STDOUT.sync = true

module AWS
  module EC2InstanceTypes

    EC2_INSTANCES_URL = 'http://www.ec2instances.info/instances.json'

    def self.fetch

      if instance_source_updated?
        $logger.info { 'Fetching EC2 instance configuration data' }
        response = HTTParty.get(EC2_INSTANCES_URL)

        if response.code == 200
          process_json(response.body)
        else
          $logger.error "Could not retrieve EC2 instance metadata from #{EC2_INSTANCES_URL}"
          $logger.debug e
        end

      else
        $logger.info "No published updates to EC2 instance configurations"
      end

    end


    # private methods
    def self.instance_source_updated?
      etag = ETag.find_or_create_by(name: 'ec2info')
      response = HTTParty.head(EC2_INSTANCES_URL)
      if ( etag.etag != response['etag'] )
        etag.update_attribute(:etag, response.headers['etag'])
        true
      else
        false
      end
    end

    def self.process_json(response_body)
      JSON.parse(response_body).each do |ec2_instance|
        type = ec2_instance['instance_type']
        instance = InstanceType.find_or_initialize_by(name: type)
        instance.cores = ec2_instance['vCPU']
        instance.cpu_speed_ghz = infer_speed(type)
        instance.memory_gb = ec2_instance['memory']
        instance.network = ec2_instance['network_performance']
        instance.save
        $logger.debug { "Saving instance type: #{type}" }
      end
      $logger.info { "#{InstanceType.count} EC2 instance types saved" }
    end

    def self.infer_speed(instance_type)
      if config = InventoryHelper::INSTANCE_TYPES[instance_type]
        config[:cpu_speed_ghz]
      elsif instance_type.match(/^t\d/)
        3.3
      elsif instance_type.match(/^c\d/)
        2.9
      else
        2.5
      end
    end

  end
end
