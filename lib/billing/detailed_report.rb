require 'aws_helper'
require 'fastest-csv'
require 'open3'

module AWS
  module DetailedReport
    include AWSHelper

    def self.fetch
      detailed_report_bucket = PropertyHelper.detailed_report_bucket

      if  detailed_report_bucket.empty?
        puts "Detailed billing information not provided; skipping"
        return
      end

      key = "#{billing_id}-aws-billing-detailed-line-items-with-resources-and-tags-#{Time.now.strftime('%Y-%m')}.csv.zip"
      puts "Retrieving detailed report manifest at #{key}"

      response = Clients.s3.get_object({bucket: detailed_report_bucket, key: key}, target: "/tmp/#{key}")
      # TODO consider streaming straight to uncompression routine?
      # https://aws.amazon.com/blogs/developer/downloading-objects-from-amazon-s3-using-the-aws-sdk-for-ruby/

      unzip_io = IO.popen("/usr/bin/funzip /tmp/#{key}", 'rb')
      csv = FastestCSV.new(unzip_io)
      flush_reports
      persist csv

    end

    def self.billing_id
      @@billing_id =
        begin
          detailed_report_bucket = PropertyHelper.detailed_report_bucket
          response = Clients.s3.list_objects_v2(bucket: detailed_report_bucket)
          key = response.contents.first.key
          key.match(/(\d+)-/)[1]
        end
    end

    def self.price_details(instance_id)
      criteria = {
        resource_id: instance_id,
        usage_type: /^(SpotUsage|BoxUsage):/i
      }

      report = ReportRow.where(criteria).sort(usage_start_date: -1).first
      return unless report

      { cost_per_hour: report.cost_per_hour,
        billing_resource: "Detailed Report" }.to_dot
    end

    private

    def self.persist(csv)
      puts "Saving new detailed report details to DB"
      headers = csv.shift
      cost_index = headers.index('BlendedCost') || headers.index('Cost')
      resource_index = headers.index('ResourceId')
      usage_start_index = headers.index('UsageStartDate')
      usage_type_index = headers.index('UsageType')

      while row = csv.shift
        ReportRow.new(resource_id:      row[resource_index],
                      usage_type:       row[usage_type_index],
                      usage_start_date: row[usage_start_index],
                      cost_per_hour:    row[cost_index]).save!
      end
    end

    def self.flush_reports
      puts "Removing old detailed report details from DB"
      ReportRow.destroy_all
    end

    # def self.date_range
    #   beginning_of_month = Date.today.beginning_of_month.to_s.gsub("-", "")
    #   beginning_of_next_month = Date.today.next_month.beginning_of_month.to_s.gsub("-", "")

    #   "#{beginning_of_month}-#{beginning_of_next_month}"
    # end
  end
end
