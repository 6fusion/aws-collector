require 'thread'

class DummyWaitingProcess
  def run
    health_endpoint = HealthEndpoint.new

    begin
      health_endpoint.start
      puts 'Waiting for Ctrl-C'
      sleep
    rescue Interrupt
      puts 'Got Ctrl-C, exit'
      exit
    ensure
      health_endpoint.shutdown
    end
  end

end
