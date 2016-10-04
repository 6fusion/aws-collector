desc 'Starting metric collector'

task :collect_samples do
  MetricCollector.new.collect
end