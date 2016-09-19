desc 'Starting metric collector'

task :collect, [:metric_name] do |t, args|
  Mongoid.load!('./config/mongoid.yml', ENV['MONGOID_ENV'] || :development)
  metric_collector = MetricCollector.new
  time_options = {start_time: 1.day.ago.iso8601,
                  end_time: Time.now.iso8601}

  metric_collector.process(time_options)
end