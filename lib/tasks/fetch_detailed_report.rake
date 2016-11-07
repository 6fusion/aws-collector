desc 'Fetching AWS detailed report'

task :fetch_detailed_report do
  AWS::DetailedReport.fetch
end
