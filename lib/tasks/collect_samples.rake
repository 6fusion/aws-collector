desc 'Starting metric collector'

task :collect_samples do
  result = MetricCollector.new.collect
  puts "No inventory found, cant collect metrics" unless result
end