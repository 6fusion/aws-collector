desc 'Collect the inventory data and put to MongoDB'

task :collect_inventory do
  connector = InventoryConnector.new
  collector = InventoryCollector.new

  connector.check_organization_exist

  begin # FIXME remove post Uber debug
    ## FIXME handle nil old_inventory
    old_inventory = collector.current_inventory
    actual_inventory = collector.collect_inventory

    if actual_inventory.different_from_old?(old_inventory)
      connector.send_infrastructure(actual_inventory)
    end

    # FIXME make configurable
    pool = Concurrent::ThreadPoolExecutor.new(min_threads: 1,
                                              max_threads: 10,
                                              max_queue: 0,
                                              fallback_policy: :caller_runs)


    # TODO map old inventory to custom_ids, reduce memory overhead?
    actual_inventory.compare_hosts(old_inventory) do |new_host, old_host|

      pool.post do
        connector.create_host(new_host) if old_host.nil?
        connector.delete_host(old_host.custom_id, old_host.to_payload) if new_host.nil?
        next if new_host.nil? || old_host.nil?

        machine_id = new_host.custom_id
        connector.patch_host(machine_id, new_host.to_payload) if new_host.different_from_old?(old_host)

        new_host.compare_disks(old_host) do |new_disk, old_disk|
          connector.create_disk(machine_id, new_disk) if old_disk.nil?
          connector.delete_disk(old_disk.custom_id, old_disk.to_payload) if new_disk.nil?
          next if new_disk.nil? || old_disk.nil?

          connector.patch_disk(new_disk.custom_id, new_disk.to_payload) if new_disk.different_from_old?(old_disk)
        end

        new_host.compare_nics(old_host) do |new_nic, old_nic|
          connector.create_nic(machine_id, new_nic) if old_nic.nil?
          connector.delete_nic(old_nic.custom_id, old_nic.to_payload) if new_nic.nil?
          next if new_nic.nil? || old_nic.nil?

          connector.patch_nic(new_nic.custom_id, new_nic.to_payload) if new_nic.different_from_old?(old_nic)
        end
      end
    end

    pool.shutdown
    pool.wait_for_termination

    collector.save! actual_inventory

  rescue => e
    $logger.error e.message
    puts e.backtrace
  end
    

end
