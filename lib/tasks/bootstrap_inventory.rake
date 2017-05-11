desc 'Initialize and syncronize inventory with API'

task :bootstrap_inventory do
  $stdout.sync = true
  puts "Bootstrapping inventory"
  $logger = Logger.new($stdout)
  $logger.level = ENV['LOG_LEVE'] || Logger::INFO
  $logger.info "Boostrapping inventory"
  connector = InventoryConnector.new
  collector = InventoryCollector.new

  $logger.debug "Checking that organization exists"
  connector.check_organization_exist

  $logger.debug "Collecting AWS inventory"
  actual_inventory = collector.collect_inventory

  $logger.debug "Posting infrastructure"
  connector.send_infrastructure(actual_inventory)

  # Add in some threading?
  threads = []
  $logger.debug "Validating collected inventory against API invenetory"
  actual_inventory.hosts.each do |host|
    threads << Thread.new {
      reponse = connector.check_machine_exists(host)
      if reponse.code == 404
        connector.create_host(host)
      end
    }

    if threads.size > 5
      threads.map(&:join)
      threads = []
    end
  end

  collector.save! actual_inventory

  $logger.debug "Finished bootstrapping inventory"


end
