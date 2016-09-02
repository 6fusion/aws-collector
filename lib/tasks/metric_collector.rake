desc 'Starting metric collector'

task :collect do
  Mongoid.load!('./config/mongoid.yml', ENV['MONGOID_ENV'] || :development)
  metric_collector = MetricCollector.new
  time_options = {start_time: 1.day.ago.iso8601,
                  end_time: Time.now.iso8601}

  metric_collector.process_ec2_metric('CPUUtilization', time_options)
  metric_collector.process_ebs_metric('VolumeReadBytes', time_options)
end