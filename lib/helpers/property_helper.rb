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

  def self.read_property(name, default = nil)
    ENV[name] || read_secret_property(name) || default || fail("Property #{name} was not found")
  end

  private

  def self.read_secret_property(name)
    # todo: implement it when we integrate stuff with Kubernetus
  end
end
