desc 'Fetching AWS detailed report'

task :fetch_detailed_report do
  begin
    AWS::DetailedReport.fetch
  rescue
    puts 'Unable to get detailed report from S3'
  end
end
