require "aws_helper"
require "zipruby"
require "property_helper"

module AWS
  module DetailedReport
    include AWSHelper
    include PropertyHelper

    def self.fetch
      report_manifest_key = "/#{detailed_report_prefix}/#{date_range}/#{detailed_report_prefix}-Manifest.json"

      puts "Retrieving detailed report manifest from: #{report_manifest_key}"

      response = Clients.s3.get_object(bucket: detailed_report_bucket, key: report_manifest_key)
      report_manifest = JSON(response.body.read)

      bucket = report_manifest["bucket"]
      key = report_manifest["reportKeys"].first

      puts "Retrieving detailed report from bucket: #{bucket} | using key: #{key}"

      report_zip = Clients.s3.get_object(bucket: bucket, key: key).body.read

      Zip::Archive.open_buffer(report_zip) do |archive|
        archive.fopen(archive.get_name(0)) do |file|
          flush_reports if file
          persist file.read
        end
      end
    end

    def self.cost_per_hour(instance_id)
      criteria = {
        resource_id: instance_id,
        usage_type: /^(SpotUsage|BoxUsage):/i
      }

      report = ReportRow.where(criteria).sort(usage_start_date: -1).first
      return unless report

      report.cost_per_hour
    end

    private

    def self.persist(report_csv)
      puts "Saving new detailed report details to DB"
      CSV.parse(report_csv, headers: true).each do |row|
        ReportRow.new(resource_id: row["lineItem/ResourceId"],
                      usage_type: row["lineItem/UsageType"],
                      usage_start_date: row["lineItem/UsageStartDate"],
                      usage_end_date: row["lineItem/UsageEndDate"],
                      description: row["lineItem/LineItemDescription"],
                      cost_per_hour: row["lineItem/BlendedCost"]).save!
      end
    end

    def self.flush_reports
      puts "Removing old detailed report details from DB"
      ReportRow.destroy_all
    end

    def self.date_range
      beginning_of_month = Date.today.beginning_of_month.to_s.gsub("-", "")
      beginning_of_next_month = Date.today.next_month.beginning_of_month.to_s.gsub("-", "")

      "#{beginning_of_month}-#{beginning_of_next_month}"
    end
  end
end
