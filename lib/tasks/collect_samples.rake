desc 'Starting metric collector'

task :collect_samples, [:metric_name] do
  MetricCollector.new(
      start_time: 1.day.ago.iso8601,
      end_time: Time.now.iso8601).collect
end