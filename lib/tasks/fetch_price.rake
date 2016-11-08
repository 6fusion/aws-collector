desc 'Fetching AWS price list'

task :fetch_price do
  AWS::PriceList.fetch
end
