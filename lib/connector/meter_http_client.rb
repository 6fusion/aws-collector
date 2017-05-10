require 'httparty'
require 'uri'
require 'logger'

class MeterHttpClient
  include HTTParty

  headers content_type: "application/json"

  def initialize
    @logger = ::Logger.new(STDOUT)
    @logger.level = ENV['LOG_LEVEL'] || 'info'
  end

  def samples(payload)
    send_to_meter(method: :post,
                  endpoint: "/api/v1/samples.json",
                  body: { samples: payload }.to_json)
  end

  def create_machine(infrastructure_id, payload)
    @logger.debug { "Creating machine #{payload[:name]}/#{payload[:custom_id]} under #{infrastructure_id}" }
    send_to_meter(method: :post,
                  endpoint: URI.escape("/api/v1/infrastructures/#{infrastructure_id}/machines.json"),
                  body: payload.to_json)
  end

  def update_machine(machine_id, payload)
    @logger.debug { "Updating machine #{payload} under #{infrastructure_id}" }
    send_to_meter(method: :patch,
                  endpoint: "/api/v1/machines/#{machine_id}.json",
                  body: payload.to_json)
  end

  def create_disk(machine_id, payload)
    send_to_meter(method: :post,
                  endpoint: "/api/v1/machines/#{machine_id}/disks.json",
                  body: payload.to_json)
  end

  def update_disk(disk_id, payload)
    send_to_meter(method: :patch,
                  endpoint: "/api/v1/disks/#{disk_id}.json",
                  body: payload.to_json)
  end

  def create_nic(machine_id, payload)
    send_to_meter(method: :post,
                  endpoint: "/api/v1/machines/#{machine_id}/nics.json",
                  body: payload.to_json)
  end

  def update_nic(nic_id, payload)
    send_to_meter(method: :patch,
                  endpoint: "/api/v1/nics/#{nic_id}.json",
                  body: payload.to_json)
  end

  def infrastructures(organization_id)
    send_to_meter(method: :get,
                  endpoint: "/api/v1/infrastructures.json",
                  query: {organization_id: organization_id}
    )
  end

  def post_infrastructure(payload, organization_id)
    send_to_meter(method: :post,
                  endpoint: URI.escape("/api/v1/organizations/#{organization_id}/infrastructures.json"),
                  body: payload.to_json)
  end

  def get_infrastructure(infrastructure_id)
    send_to_meter(method: :get,
                  endpoint: URI.escape("/api/v1/infrastructures/#{infrastructure_id}.json"))
  end

  def update_infrastructure(payload, infrastructure_id)
    send_to_meter(method: :patch,
                  endpoint: URI.escape("/api/v1/infrastructures/#{infrastructure_id}.json"),
                  body: payload.to_json)
  end

  def delete_infrastructure(infrastructure_id)
    send_to_meter(method: :delete,
                  endpoint: URI.escape("/api/v1/infrastructures/#{infrastructure_id}.json"))
  end

  def get_organization(organization_id)
    send_to_meter(method: :get,
                  endpoint: URI.escape("/api/v1/organizations/#{organization_id}.json"))
  end

  def get_machine(machine_id)
    send_to_meter(method: :get,
                  endpoint: URI.escape("/api/v1/machines/#{machine_id}.json"))
  end


  private

  def send_to_meter(options)
    host = (PropertyHelper.use_ssl ? "https://" : "http://") + PropertyHelper.meter_host
    port = PropertyHelper.meter_port
    host = port&.empty? ? host : "#{host}:#{port}"

    self.class.base_uri(host)

    req_options = {
        query: query_with_token(options),
        verify: PropertyHelper.verify_ssl
    }

    if [:post, :patch].include? options[:method]
      req_options[:body] = options[:body]
    end

    response = self.class.send(options[:method], options[:endpoint], req_options)

    response.success? || ((options[:method] != :post) and (response.code == 404)) ||
      raise("Response to meter has failed. Response: #{response}\nDetails:\n#{full_options_to_str(options)}")
    response
  end

  def full_options_to_str(options)
    "#{options_to_str(options)}\n#{options[:body]}"
  end

  def query_with_token(options)
    query = options[:query] || {}
    token = PropertyHelper.token
    query[:access_token] = token unless token.empty?
    query
  end

  def options_to_str(options)
    method = options[:method].upcase
    url = options[:endpoint]
    "#{method} #{url}"
  end
end
