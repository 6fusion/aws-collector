require 'aws-sdk'

RSpec.shared_context 'shared collectors context' do
  let(:ec2_client) { double }
  let(:cw_client) { double }
  let(:resource) { double }
  let(:region) { double(region_name: 'us-west-2') }
  let(:instance) {
    double(
        instance_id: '_id_1',
        client: {config: {region: region.region_name}}.to_dot,
        block_device_mappings: [],
        root_device_type: 'ebs'
    )
  }

  before(:each) do
    allow(Aws::EC2::Client).to receive(:new).and_return(ec2_client)
    allow(ec2_client).to receive_message_chain(:describe_regions, :data, :regions).and_return([region])
    allow(Aws::EC2::Resource).to receive(:new).with(region: region.region_name).and_return(resource)
    allow(resource).to receive_message_chain(:instances, :entries).and_return([instance])
    allow(Aws::CloudWatch::Client).to receive(:new).with(region: region.region_name).and_return(cw_client)
  end
end