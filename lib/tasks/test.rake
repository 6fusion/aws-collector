require 'rspec/core/runner'

task :test do
  RSpec::Core::Runner.run(%w(-I . spec/))
end