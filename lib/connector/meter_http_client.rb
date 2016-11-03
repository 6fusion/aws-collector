require "httparty"

class MeterHttpClient
  include HTTParty

  base_uri "http://a301086896f9d11e69df00ac2d1bb6f0-1419040031.us-east-1.elb.amazonaws.com"
  headers content_type: "application/json"

  def samples(payload)
    send_to_meter(method: :post,
                  endpoint: "/api/v1/samples.json",
                  body: { samples: payload }.to_json)
  end

  def create_machine(infrastructure_id, payload)
    send_to_meter(method: :post,
                  endpoint: "/api/v1/infrastructures/#{infrastructure_id}/machines.json",
                  body: payload.to_json)
  end

  def update_machine(machine_id, payload)
    send_to_meter(method: :patch,
                  endpoint: "/api/v1/machines/#{machine_id}.json",
                  body: payload.to_json)
  end

  def infrastructures(organization_id)
    send_to_meter(method: :get,
                  endpoint: "/api/v1/infrastructures.json?organization_id=#{organization_id}")
  end

  def post_infrastructure(payload, organization_id)
    send_to_meter(method: :post,
                  endpoint: "/api/v1/organizations/#{organization_id}/infrastructures.json",
                  body: payload.to_json)
  end

  def get_infrastructure(infrastructure_id)
    send_to_meter(method: :get,
                  endpoint: "/api/v1/infrastructures/#{infrastructure_id}.json")
  end

  def update_infrastructure(payload, infrastructure_id)
    send_to_meter(method: :patch,
                  endpoint: "/api/v1/infrastructures/#{infrastructure_id}.json",
                  body: payload.to_json)
  end

  def delete_infrastructure(infrastructure_id)
    send_to_meter(method: :delete,
                  endpoint: "/api/v1/infrastructures/#{infrastructure_id}.json")
  end

  def get_organization(organization_id)
    send_to_meter(method: :get,
                  endpoint: "/api/v1/organizations/#{organization_id}.json")
  end

  private

  def send_to_meter(options)
    puts "Sending reqest to meter: #{options_to_str(options)}"
    response = case options[:method]
      when :get
        self.class.get(options[:endpoint])
      when :post
        self.class.post(options[:endpoint], body: options[:body])
      when :patch
        self.class.patch(options[:endpoint], body: options[:body])
      when :delete
        self.class.delete(options[:endpoint])
               end
    response.success? || response.code == 404 ||
        raise("Response to meter has failed. Response: #{response}\nDetails:\n#{full_options_to_str(options)}")
    response
  end

  def full_options_to_str(options)
    "#{options_to_str(options)}\n#{options[:body]}"
  end

  def options_to_str(options)
    method = options[:method].upcase
    url = options[:endpoint]
    "#{method} #{url}"
  end
end
