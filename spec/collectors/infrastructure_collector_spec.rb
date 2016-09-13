require 'collectors/infrastructure_collector'
require 'shared_context'
require 'aws-sdk'

RSpec.describe InfrastructureCollector do
  include_context 'shared collectors context'

  context 'with some instances available' do
    it 'get instances' do
      expect(subject.instances).to eq([instance])
    end
  end

end