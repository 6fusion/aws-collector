desc 'Fetching EC2 instance types'

task :fetch_instance_types do
  begin
    AWS::EC2InstanceTypes.fetch
  rescue => e
    $logger.error "Unable to retrieve EC2 instance configuration data"
    $logger.error e.message
    $logger.debug e.backtrace.join("\n")
  end
end
