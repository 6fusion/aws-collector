require 'rspec/core/runner'

task :test do
  $:.unshift File.expand_path('spec/collectors/shared')
  Mongoid.load!('./config/mongoid.yml', :test)
  RSpec::Core::Runner.run(%w(-I . spec/))
end