require 'bundler/setup'
require 'yaml'
require 'hash_dot'

Dir.glob(File.join('.', 'lib', '**', '*.rb'), &method(:require))

CONFIG = YAML::load_file(File.expand_path('../config/application.yml', __FILE__)).to_dot

Dir.glob('lib/tasks/*.rake').each { |rake_task| load rake_task }
