require 'webrick'
require 'webrick/https'
require 'openssl'
require 'forwardable'

class HealthEndpoint
  extend Forwardable

  def initialize
    cert, pkey = ssl_certificate_and_key

    @server = WEBrick::HTTPServer.new(Port: CONFIG.server.port,
                                      SSLEnable: true,
                                      SSLCertificate: cert,
                                      SSLPrivateKey: pkey)

    @server.mount_proc '/health' do |request, response|
      response.status = 200
    end
  end

  def_delegators :@server, :start, :shutdown

  private

  def ssl_certificate_and_key
    cert = read_file '../../.ssl/6fusion.cer'
    pkey = read_file '../../.ssl/6fusion.openssl'
    return OpenSSL::X509::Certificate.new(cert), OpenSSL::PKey::RSA.new(pkey)
  end

  def read_file(path)
    File.read File.expand_path(path, __FILE__)
  end
end
