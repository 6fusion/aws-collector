desc 'Sending samples to meter'

task :send_samples do
  samples = Sample.all.map{ |sample| sample.to_payload }
  return unless samples

  puts "Sending samples to meter"
  response = MeterHttpClient.new.samples(samples)
  if response.code == 204
    puts "Samples have been sent, destroying samples in Mongo"
    Sample.destroy_all
  else
    puts "Error occurred during sending samples to meter. Status: #{response.code}"
  end
end