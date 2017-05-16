desc 'Initialize and syncronize inventory with API'

task :bootstrap_inventory do
  $logger.info "Boostrapping inventory"
  connector = InventoryConnector.new
  collector = InventoryCollector.new

  $logger.debug "Checking that organization exists"
  connector.check_organization_exist

  $logger.debug "Collecting AWS inventory"
  actual_inventory = collector.collect_inventory

  $logger.debug "Posting infrastructure"
  connector.send_infrastructure(actual_inventory)

  # FIXME make configurable
  pool = Concurrent::ThreadPoolExecutor.new(min_threads: 1,
                                            max_threads: 10,
                                            max_queue: 0,
                                            fallback_policy: :caller_runs)
  $logger.debug "Validating collected inventory against API invenetory"

  actual_inventory.hosts.each do |host|
    pool.post {
      reponse = connector.check_machine_exists(host)
      if reponse.code == 404
        connector.create_host(host)
      end
    }
  end
  pool.shutdown
  pool.wait_for_termination

  collector.save! actual_inventory

  $logger.debug "Finished bootstrapping inventory"


end
