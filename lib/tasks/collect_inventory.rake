desc 'Collect the inventory data and put to MongoDB'
task :collect_inventory do
  InventoryCollector.new.collect_inventory
end