module PropertyHelper

  def self.infrastructure_id
    read_property("INFRASTRUCTURE_ID")
  end

  def self.infrastructure_name
    read_property("INFRASTRUCTURE_NAME")
  end

  def self.organization_id
    read_property("ORGANIZATION_ID")
  end

  def self.aws_access_key
    read_property("AWS_ACCESS_KEY")
  end

  def self.aws_secret_key
    read_property("AWS_SECRET_KEY")
  end

  def self.detailed_report_bucket
    read_property("DETAILED_REPORT_BUCKET")
  end

  def self.detailed_report_prefix
    read_property("DETAILED_REPORT_PREFIX")
  end

  def self.read_property(path, default = nil)
    name = path.split("/").last.upcase
    ENV[name] || read_secret_property(path) ||
      default || fail("Property with #{path} was not found")
  end

  private

  def self.read_secret_property(path)
    property = "#{ENV["SECRET_DIR"]}/#{path}"
    return unless File.exist?(property)

    value = File.read(property).chomp.strip
    return true if value == "true"
    return false if value == "false"
    value
  end
end
