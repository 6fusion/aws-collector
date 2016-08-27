desc 'Starting metric collector'

task :collect do
  Mongoid.load!('./config/mongoid.yml', ENV['MONGOID_ENV'] || :development)
  MetricCollector.new.process_metrics('CPUUtilization', start_time: 1.day.ago.iso8601, end_time: Time.now.iso8601)
end