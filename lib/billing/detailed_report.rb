require 'aws_helper'
require 'fastest-csv'

module AWS
  module DetailedReport
    include AWSHelper

    def self.fetch
      detailed_report_bucket = PropertyHelper.detailed_report_bucket
      if  detailed_report_bucket.empty?
        $logger.info "Detailed billing information not provided; skipping"
        return
      end
      $logger.debug "Using #{detailed_report_bucket} for billing retrieval"

      key = "#{billing_id}-aws-billing-detailed-line-items-with-resources-and-tags-#{Time.now.strftime('%Y-%m')}.csv.zip"
      $logger.info "Retrieving detailed report manifest at #{key}"
      start_time = Time.now

      $logger.info "Retrieving detailed billing from S3"
      resp = Clients.s3.get_object({ bucket:'bucket-name', key:'object-key' }, target: '/tmp/billing.zip')
      $logger.info "Detailed billing retrieval complete. Processing line items"

      # cavaet emptor :https://aws.amazon.com/blogs/developer/downloading-objects-from-amazon-s3-using-the-aws-sdk-for-ruby/
      # Clients.s3.get_object({bucket: detailed_report_bucket, key: key}){|chunk|
      #        zipped_to_csv_io.write chunk }

      zipped_to_csv_io = IO.popen('/usr/bin/funzip /tmp/billing.zip', 'rb+')
      zipped_to_csv_io.sync = true
      csv = FastestCSV.new(zipped_to_csv_io)
      flush_reports
      persist csv
      # reader_thread = Thread.new {
      #   persist csv }
      # reader_thread.join
      $logger.debug "Finished processing billing in #{Time.now - start_time} seconds"
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
      $logger.info "Saving new detailed report details to DB"
      headers = csv.shift
      cost_index = headers.index('BlendedCost') || headers.index('Cost')
      resource_index = headers.index('ResourceId')
      usage_start_index = headers.index('UsageStartDate')
      usage_type_index = headers.index('UsageType')
      count = 0
      while row = csv.shift
        count += 1
        $logger.debug "Processed #{count} billing items" if count % 100_000 == 0
        ReportRow.new(resource_id:      row[resource_index],
                      usage_type:       row[usage_type_index],
                      usage_start_date: row[usage_start_index],
                      cost_per_hour:    row[cost_index]).save!
      end

      $logger.info "Processed #{count} billing records"
    end

    def self.flush_reports
      $logger.debug "Removing old detailed report details from DB"
      ReportRow.collection.drop
    end

    # def self.date_range
    #   beginning_of_month = Date.today.beginning_of_month.to_s.gsub("-", "")
    #   beginning_of_next_month = Date.today.next_month.beginning_of_month.to_s.gsub("-", "")

    #   "#{beginning_of_month}-#{beginning_of_next_month}"
    # end
  end
end
