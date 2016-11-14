desc 'Collect the inventory data and put to MongoDB'

task :collect_inventory do
  connector = InventoryConnector.new
  collector = InventoryCollector.new

  connector.check_organization_exist

  old_inventory_json = collector.current_inventory_json
  actual_inventory = collector.collect_inventory

  if actual_inventory.different_from_old?(old_inventory_json)
    connector.send_infrastructure(actual_inventory)
  end

  collector.save! actual_inventory

  actual_inventory.compare_hosts(old_inventory_json) do |new_host, old_host|
    connector.create_host(new_host) if old_host.nil?
    connector.delete_host(old_host[:id], old_host) if new_host.nil?
    next if new_host.nil? || old_host.nil?
  end
end
