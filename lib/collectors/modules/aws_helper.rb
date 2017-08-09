module AWSHelper

  module Clients
    def self.cloud_watch(region)
      @@cloud_watch ||= Hash.new
      @@cloud_watch[region] ||=
        Aws::CloudWatch::Client.new(
          region: region,
          credentials: AWSHelper::Identity.assume_role(:cloud_watch, region))
    end

    def self.ec2(region = PropertyHelper.aws_region)
      @@ec2 ||= Hash.new
      @@ec2[region] ||=
        Aws::EC2::Client.new(
          region: region,
          credentials: AWSHelper::Identity.assume_role(:ec2, region))
    end

    def self.s3(region = PropertyHelper.billing_region)
      @@s3 ||=
        Aws::S3::Client.new(
          region: region,
          credentials: AWSHelper::Identity.assume_role(:s3, region))
    end

  end

  module Resources
    def self.ec2(region)
      Aws::EC2::Resource.new(
        region: region,
        credentials: AWSHelper::Identity.assume_role(:ec2, region))
    end
  end

  module Identity
    def self.assume_role(role, region)
      role.eql?(:s3) ? billing_role : collection_role
    end

    def self.role_options
      { access_key_id: PropertyHelper.aws_access_key,
        secret_access_key: PropertyHelper.aws_secret_key,
        role_session_name: 'aws-collector' }.merge( ENV['EXTERNAL_ID']&.empty? ? {} : { external_id: ENV['EXTERNAL_ID'] } )
    end

    def self.simple_credentials
      @@simple_credentials ||= Aws::Credentials.new(PropertyHelper.aws_access_key, PropertyHelper.aws_secret_key)
    end

    def self.billing_role
      @@billing_sts ||= PropertyHelper.billing_arn ?
                          Aws::AssumeRoleCredentials.new( role_options.merge({ role_arn: PropertyHelper.billing_arn }) ) :
                          simple_credentials
    end

    def self.collection_role
      @collection_sts ||= PropertyHelper.collection_arn ?
                            Aws::AssumeRoleCredentials.new( role_options.merge({ role_arn: PropertyHelper.collection_arn }) ) :
                            simple_credentials
    end

    def self.account_id
      begin
        # If we have IAM access, just return the fields
        "#{iam_userid}:#{iam_username}"
      rescue Aws::IAM::Errors::AccessDenied => e
        # If not, the exception message actually includes this information as well
        md = e.message.match(%r|arn:aws:iam::(?<userid>\d+):[^\s]+/(?<username>[^\s]+) is not authorized|)
        "#{md[:userid]}:#{md[:username]}"
      end
    end

    def self.account_id(region = ENV['AWS_REGION'])
      begin
        # If they have IAM access, just return the fields
        "#{iam_userid}:#{iam_username}"
      rescue Aws::IAM::Errors::AccessDenied => e
        # If not, the exception message actually includes this information as well
        md = e.message.match(%r|arn:aws:iam::(?<userid>\d+):[^\s]+/(?<username>[^\s]+) is not authorized|)
        "#{md[:userid]}:#{md[:username]}"
      end
    end

    def self.iam
      Aws::IAM::Client.new(
        access_key_id: PropertyHelper.aws_access_key,
        secret_access_key: PropertyHelper.aws_secret_key)
    end

    def self.iam_username()
      iam.get_user.data.user.user_name
    end

    def self.iam_userid()
      iam.get_user.data.user.user_id
    end
  end

end

