desc 'Starting AWS collector'
task :start do
  health_endpoint = HealthEndpoint.new
  scheduler = Scheduler.new

  Mongoid::Tasks::Database::create_indexes

  begin
    puts 'Waiting for Ctrl-C'
    scheduler.start
    health_endpoint.start
  rescue Interrupt
    puts 'Got Ctrl-C, exit'
  ensure
    health_endpoint.shutdown
    scheduler.shutdown
  end
end
