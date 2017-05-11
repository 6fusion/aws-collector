desc 'Initialize and syncronize inventory with API'

task :bootstrap_inventory do
  $logger.info "Boostrapping inventory"
  connector = InventoryConnector.new
  collector = InventoryCollector.new

  connector.check_organization_exist

  actual_inventory = collector.collect_inventory

  connector.send_infrastructure(actual_inventory)

  # Add in some threading?
  threads = []
  $logger.debug "Validating collected inventory against API invenetory"
  actual_inventory.hosts.each do |host|
    threads << Thread.new {
      reponse = connector.get_machine(host)
      if reponse["code"] == 404
        connector.create_host(host)
      end
    }

    if threads.size > 5
      threads.map(&:join)
      threads = []
    end
  end
  $logger.debug "Finished bootstrapping inventory"


end
