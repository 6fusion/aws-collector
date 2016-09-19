module PropertyHelper
  def self.init_mongo
    Mongoid.load!('./config/mongoid.yml', PropertyHelper.read_property("MONGOID_ENV", :development))
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