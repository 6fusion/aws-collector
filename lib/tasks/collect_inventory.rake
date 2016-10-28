desc 'Collect the inventory data and put to MongoDB'

task :collect_inventory do
  connector = InventoryConnector.new
  collector = InventoryCollector.new

  connector.check_organization_exist

  actual_inventory = collector.collect_inventory

  MetricCollector.new.collect

  connector.send_infrastructure(actual_inventory)
  actual_inventory.hosts.each { |host| connector.send_host(host) }

  collector.save! actual_inventory
end
