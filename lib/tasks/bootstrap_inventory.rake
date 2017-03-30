desc 'Initialize and syncronize inventory with API'

task :bootstrap_inventory do
  puts "Boostrapping inventory"
  connector = InventoryConnector.new
  collector = InventoryCollector.new

  connector.check_organization_exist

  actual_inventory = collector.collect_inventory

  connector.send_infrastructure(actual_inventory)

  p actual_inventory
  puts "itearting over inventory"

  actual_inventory.hosts.each do |host|
    puts "checking #{host.inspect}"
    reponse = connector.get_machine(host)
    if reponse["code"] == 404
      connector.create_host(host)
    end
  end

end
