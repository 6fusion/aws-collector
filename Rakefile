require 'bundler'
require 'logger'
Bundler.require(:default)

$:.unshift File.expand_path('lib/collectors/modules'), File.expand_path('lib/collectors'), File.expand_path('lib/helpers')

STDOUT.sync = true
$logger = Logger.new(STDOUT)
$logger.level = ENV['LOG_LEVEL'] || Logger::INFO

Dir.glob(File.join('./lib/helpers/**/*.rb'), &method(:require))
Dir.glob(File.join('./lib/models/**/*.rb'), &method(:require))
Dir.glob(File.join('./lib/billing/**/*.rb'), &method(:require))
Dir.glob(File.join('./lib/collectors/**/*.rb'), &method(:require))
Dir.glob(File.join('./lib/connector/**/*.rb'), &method(:require))
Dir.glob(File.join('./lib/tasks/**/*.rb'), &method(:require))
Dir.glob(File.join('./lib/*.rb'), &method(:require))

CONFIG = YAML::load_file(File.expand_path('../config/application.yml', __FILE__)).to_dot

Mongoid.load_configuration(clients: {
    default: {
        database: 'metrics',
        hosts: ["#{PropertyHelper.mongo_host}:#{PropertyHelper.mongo_port}"],
        options: {
          max_pool_size: 20,
          min_pool_size: 2 }

    }
})

Dir.glob('lib/tasks/*.rake').each(&method(:load))
