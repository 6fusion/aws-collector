
module ShowHelper
  def client
    @client ||= MeterHttpClient.new
  end

  def pretty_puts(response)
    puts JSON.pretty_generate(JSON.parse(response.body))
    puts "HTTP Status: #{response.code}"
  end
end

namespace :show do
  include ShowHelper

  task :infrastructures do
    body = client.infrastructures(PropertyHelper.organization_id).body
    json = JSON.parse(body)
    json["embedded"]["infrastructures"].each do |infrastructure|
      ["id", "custom_id", "status", "organization_id", "name", "cost_per_hour"].each do |field|
        puts "#{field}: #{infrastructure[field]}"
      end
      puts "---"
    end
    puts "Total infrastructures: #{json["embedded"]["infrastructures"].size}"
  end

  task :infrastructure, :id do |t, args|
    pretty_puts client.get_infrastructure(args[:id])
  end
end


