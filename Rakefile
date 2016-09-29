require 'bundler'
Bundler.require(:default)

$:.unshift File.expand_path('lib/collectors/modules'), File.expand_path('lib/collectors'), File.expand_path('lib/helpers')

Dir.glob(File.join('./lib/**/*.rb'), &method(:require))

CONFIG = YAML::load_file(File.expand_path('../config/application.yml', __FILE__)).to_dot

Dir.glob('lib/tasks/*.rake').each(&method(:load))

Mongoid.load!('./config/mongoid.yml', ENV['MONGOID_ENV'] || :development)