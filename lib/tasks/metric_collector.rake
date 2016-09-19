desc 'Starting metric collector'

task :collect, [:metric_name] do
  Mongoid.load!('./config/mongoid.yml', ENV['MONGOID_ENV'] || :development)
  metric_collector = MetricCollector.new
  metric_collector.process(start_time: 1.day.ago.iso8601, end_time: Time.now.iso8601)
end