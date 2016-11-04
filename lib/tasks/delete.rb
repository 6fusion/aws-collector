namespace :delete do

  task :infrastructures do
    client = MeterHttpClient.new
    body = MeterHttpClient.new.infrastructures(PropertyHelper.organization_id).body
    json = JSON.parse(body)
    json["embedded"]["infrastructures"].each do |infrastructure|
      infrastructure_id = infrastructure["id"]
      puts "Deleting infrastructure with id #{infrastructure_id}..."
      puts client.delete_infrastructure(infrastructure_id)
    end
  end
end
