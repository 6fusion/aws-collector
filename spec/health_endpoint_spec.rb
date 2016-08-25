require 'health_endpoint'
require 'net/http'
require 'open-uri'

RSpec.describe HealthEndpoint do
  HEALTH_URL = "https://localhost:#{CONFIG.server.port}/health"

  context "when is not running" do
    it do
      expect {
        open(HEALTH_URL, ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE)
      }.to raise_error(Errno::ECONNREFUSED)
    end
  end

  context "when is up and running" do
    it do
      subject.start_async
      response_status = open(HEALTH_URL, ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE).status
      expect(response_status).to eq ["200", "OK "]
      subject.shutdown
    end
  end
end