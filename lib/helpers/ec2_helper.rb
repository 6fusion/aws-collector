module Ec2Helper
  def aws_ec2_resource(region)
    Aws::EC2::Resource.new(
        region: region,
        access_key_id: PropertyHelper.aws_access_key,
        secret_access_key: PropertyHelper.aws_secret_key)
  end

  def aws_client_ec2(region = "us-east-1")
    Aws::EC2::Client.new(
      region: region,
      access_key_id: PropertyHelper.aws_access_key,
      secret_access_key: PropertyHelper.aws_secret_key)
  end
end