require 'pry'
desc 'IRB session with libraries loaded'
task :console do
  ENV['AWS_REGION'] ||= 'us-east-1'
  ENV['MONGO_SERVICE_HOST'] ||= 'foo'
  ENV['MONGO_SERVICE_PORT'] ||= '27107'
  pry
end
