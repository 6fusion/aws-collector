desc 'Initialize and syncronize inventory with API'

task :bootstrap_inventory do
  puts "Boostrapping inventory"
  connector = InventoryConnector.new
  collector = InventoryCollector.new

  connector.check_organization_exist

  # FIXME remove this once Uber debug has finished
  if InstanceType.count == 0
    actual_inventory = collector.collect_inventory

    connector.send_infrastructure(actual_inventory)

    # Add in some threading?
    actual_inventory.hosts.each do |host|
      reponse = connector.get_machine(host)
      if reponse["code"] == 404
        connector.create_host(host)
      end
    end

  end

end
