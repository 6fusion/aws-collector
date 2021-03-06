require 'aws_helper'
require 'fastest-csv'

STDOUT.sync = true

module AWS
  module DetailedReport
    include AWSHelper

    def self.fetch
      detailed_report_bucket = PropertyHelper.detailed_report_bucket
      if  detailed_report_bucket.empty?
        $logger.info "Detailed billing information not provided; skipping"
        return
      end

      key = "#{billing_id}-aws-billing-detailed-line-items-with-resources-and-tags-#{Time.now.strftime('%Y-%m')}.csv.zip"
      $logger.info "Retrieving detailed report manifest at #{detailed_report_bucket}/#{key}"
      start_time = Time.now

      target = '/tmp/billing.zip'
      target_file = File.open(target, 'wb')
      response = Clients.s3.get_object(bucket: detailed_report_bucket, key: key, response_target: target_file)
      target_file.close
      $logger.info "Download complete. etag: #{response.etag}, length: #{response.content_length}, parts_count: #{response.parts_count if response.respond_to?(:parts_count)}"

      etag = ETag.find_or_create_by(name: 'billing')
      if etag.etag == response.etag
        $logger.info "No billing updates"
        return
      else
        etag.update_attribute(:etag, response.etag)
      end

      zipped_to_csv_io = IO.popen("/usr/bin/funzip #{target}", 'rb')
      zipped_to_csv_io.sync = true

      flush_reports

      csv = FastestCSV.new(zipped_to_csv_io)

      persist(csv)

#      File.delete(target)

      $logger.info "Detailed billing retrieval complete"
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

      csv.each_slice(1000) do |rows|
        count += 1
        $logger.debug "Processed #{count} billing items" if count % 100_000 == 0

        ReportRow.collection.insert_many(rows.map{|row|
                                           { resource_id: row[resource_index],
                                             usage_type:  row[usage_type_index],
                                             usage_start_date: row[usage_start_index],
                                             cost_per_hour: row[cost_index] } })
      end

      $logger.info "Processed #{ReportRow.count} billing records"
    end

    def self.flush_reports
      $logger.debug "Removing old detailed report details from DB"
      ReportRow.collection.drop
      Mongoid::Tasks::Database::create_indexes
    end

    # def self.date_range
    #   beginning_of_month = Date.today.beginning_of_month.to_s.gsub("-", "")
    #   beginning_of_next_month = Date.today.next_month.beginning_of_month.to_s.gsub("-", "")

    #   "#{beginning_of_month}-#{beginning_of_next_month}"
    # end
  end
end
