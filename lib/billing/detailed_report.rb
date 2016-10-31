module AWS
  module DetailedReport
    def self.fetch
      #todo: do load detailed report from S3 bucket
    end

    def self.cost_per_hour(instance_id)
      criteria = {
        resource_id: instance_id,
        usage_type: /^BoxUsage:/i
      }

      report = ReportRow.where(criteria).sort(usage_start_date: -1).first
      return unless report

      report.cost_per_hour
    end

    private

    def self.persist(report_csv)
      CSV.foreach(report_csv, headers: true) do |row|
        ReportRow.new(resource_id: row["lineItem/ResourceId"],
                      usage_type: row["lineItem/UsageType"],
                      usage_start_date: row["lineItem/UsageStartDate"],
                      usage_end_date: row["lineItem/UsageEndDate"],
                      description: row["lineItem/LineItemDescription"],
                      cost_per_hour: row["lineItem/BlendedCost"]).save!
      end
    end

    def self.flush
      ReportRow.destroy_all
    end
  end
end
