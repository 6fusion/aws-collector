desc 'Sending samples to meter'

task :send_samples do
  MetricsSender.new.send
end