module AWSHelper
  module Clients
    def self.cloud_watch(region)
      Aws::CloudWatch::Client.new(region: region)
    end

    def self.ec2(region = "us-east-1")
      Aws::EC2::Client.new(region: region)
    end

    def self.s3(region = "us-east-1")
      Aws::S3::Client.new(region: region)
    end
  end

  module Resources
    def self.ec2(region)
      Aws::EC2::Resource.new(region: region)
    end
  end
end
