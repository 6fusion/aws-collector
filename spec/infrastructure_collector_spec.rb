require 'collectors/infrastructure_collector'
require 'aws-sdk'

RSpec.describe InfrastructureCollector do

  context 'with some instances available' do
    it 'get instances' do
      ec2_client = double('Ec2Client')
      region = double('SomeRegion', region_name: 'us-west-2')
      resource = double('Resource')
      instance = double('Ec2Instance')

      allow(Aws::EC2::Client).to receive(:new).and_return(ec2_client)
      allow(ec2_client).to receive_message_chain(:describe_regions, :data, :regions).and_return([region])
      allow(Aws::EC2::Resource).to receive(:new).with(region: region.region_name).and_return(resource)
      allow(resource).to receive_message_chain(:instances, :entries).and_return([instance])

      expect(subject.instances).to eq([instance])
    end
  end

end