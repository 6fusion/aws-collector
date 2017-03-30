desc 'Fetching AWS detailed report'

task :fetch_detailed_report do
  begin
    AWS::DetailedReport.fetch
  rescue => e
    puts "Unable to get detailed report from S3: #{e.message}"
  end
end
