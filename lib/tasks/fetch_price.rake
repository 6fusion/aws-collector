require 'rspec/core/runner'

task :fetch_price do
  AWS::PriceList.fetch
end
