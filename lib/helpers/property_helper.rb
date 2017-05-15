module PropertyHelper

  def self.aws_region
    read_property('AWS_REGION', 'us-east-1')
  end

  def self.collection_arn
    read_env('COLLECTION_ARN')
  end

  def self.billing_arn
    read_env('BILLING_ARN')
  end

  def self.billing_region
    read_property('BILLING_REGION', 'us-east-1')
  end

  def self.external_id
    read_env('EXTERNAL_ID')
  end

  def self.infrastructure_name
    read_property('INFRASTRUCTURE_NAME')
  end

  def self.organization_id
    read_property('ORGANIZATION_ID')
  end

  def self.aws_access_key
    read_property('AWS_ACCESS_KEY')
  end

  def self.aws_secret_key
    read_property('AWS_SECRET_KEY')
  end

  def self.detailed_report_bucket
    read_property('DETAILED_REPORT_BUCKET')
  end

  def self.detailed_report_prefix
    read_env('DETAILED_REPORT_PREFIX')
  end

  def self.token
    read_property('TOKEN')
  end

  def self.meter_host
    read_property('METER_HOST')
  end

  def self.meter_port
    read_property('METER_PORT')
  end

  def self.mongo_host
    read_property('MONGO_SERVICE_HOST')
  end

  def self.mongo_port
    read_property('MONGO_SERVICE_PORT')
  end

  def self.verify_ssl
    read_property('VERIFY_SSL') == '1'
  end

  def self.use_ssl
    read_property('USE_SSL') == '1'
  end

  def self.default_disk_io
    read_env('DEFAULT_DISK_IO', '2').to_f * 1000000000
  end

  def self.default_wan_io
    read_env('DEFAULT_WAN_IO', '0.4').to_f * 1000000000
  end

  def self.default_lan_io
    read_env('DEFAULT_LAN_IO', '10').to_f * 1000000000
  end

  def self.target_utilization_percent
    read_env('TARGET_UTILIZATION_PERCENT', 100).to_f
  end

  def self.target_machines_per_core
    read_env('TARGET_MACHINES_PER_CORE', 10000).to_f
  end


  def self.read_env(name, default=nil)
    (ENV[name] and !ENV[name].blank?) ? ENV[name] : default
  end


  def self.read_property(path, default = nil)
    name = path.split('/').last.upcase
    ENV[name] || read_secret_property(path) ||
      default || fail("Property with #{path} was not found")
  end

  private

  def self.read_secret_property(path)
    property = "#{ENV['SECRET_DIR']}/#{path}"
    return unless File.exist?(property)

    value = File.read(property).chomp.strip
    return true if value == 'true'
    return false if value == 'false'
    value
  end
end
