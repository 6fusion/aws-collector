require 'rspec/core/runner'

task :fetch do
  Mongoid.load!('./config/mongoid.yml', ENV['MONGOID_ENV'] || :development)
  AWS::PriceList.fetch
end
