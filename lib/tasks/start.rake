desc 'Starting health endpoint'
task :start do
  health_endpoint = HealthEndpoint.new

  begin
    puts 'Waiting for Ctrl-C'
    health_endpoint.start
  rescue Interrupt
    puts 'Got Ctrl-C, exit'
  ensure
    health_endpoint.shutdown
  end
end
