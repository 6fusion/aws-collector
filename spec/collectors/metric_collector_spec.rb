require 'collectors/metric_collector'
require 'shared_context'
require 'aws-sdk'

RSpec.describe MetricCollector do
  include_context 'shared collectors context'

  before(:example) { Mongoid.purge! }

  context 'with empty inventory' do
    it 'returns false' do
      result = subject.collect

      expect(result).to be_falsey
    end
  end

  context 'with existing inventory' do
    let (:inventory) { double(hosts: [], custom_id: nil) }

    before(:example) do
      expect(Inventory).to receive_message_chain(:where, :first).
          and_return(inventory)
    end

    shared_examples_for 'last collected time is valid' do
      let(:matcher) { be > old_last_collected_time }

      it 'updates inventory with last collected time greater than previous' do
        new_time = nil
        expect(inventory).to receive(:update_attributes) do |arg|
          new_time = arg[:last_collected_metrics_time]
        end

        subject.collect

        expect(Time.parse(new_time)).to matcher
      end
    end

    context 'with last collected time existing in the inventory' do
      let (:old_last_collected_time) { Time.parse('2016-11-15 21:42:25 +0300') }

      before(:example) do
        allow(inventory).to receive(:last_collected_metrics_time).
            and_return(old_last_collected_time)
      end

      it_behaves_like 'last collected time is valid'
    end

    context 'with last collected time existing on Meter' do
      let (:old_last_collected_time) { Time.parse('2016-11-15 23:42:25 +0300') }
      let (:meter_response) { {
          'hosts' => [
              {last_collected_metrics_time: old_last_collected_time}
          ]
      } }

      before(:example) do
        allow(inventory).to receive(:last_collected_metrics_time).
            and_return(nil)
        allow(MeterHttpClient).to receive(:new).
            and_return(meter_client)
        allow(meter_client).to receive(:get_infrastructure).
            and_return(meter_response)
      end

      it_behaves_like 'last collected time is valid'
    end

    context 'with missing information about last collected time' do
      let (:now_time) { Time.parse('2016-11-15 23:42:25 +0300') }
      let (:meter_response) { {} }

      before(:example) do
        allow(Time).to receive(:now).and_return(now_time)
        allow(inventory).to receive(:last_collected_metrics_time)
        allow(MeterHttpClient).to receive(:new).
            and_return(meter_client)
        allow(meter_client).to receive(:get_infrastructure).
            and_return(meter_response)
      end

      it_behaves_like 'last collected time is valid' do
        let (:matcher) { be == now_time }
      end
    end

    context 'with existing last collected time and hosts available' do
      let (:inventory) { double(
          hosts: [double(
                      custom_id: '123',
                      region: 'us-west-1',
                      platform: '',
                      disks: [])],
          custom_id: nil
      ) }
      let (:last_collected_time) { Time.parse('2016-11-15 21:42:25 +0300') }
      let (:metric_value) { 10 }
      let (:datapoint) { double(
          timestamp: last_collected_time.to_s,
          average: metric_value
      ) }

      before(:example) do
        allow(inventory).to receive(:last_collected_metrics_time).
            and_return(last_collected_time)
        allow(inventory).to receive(:update_attributes)
        allow(cw_client).to receive_message_chain(:get_metric_statistics, :data, :datapoints).
            and_return([datapoint])
      end

      it 'saves samples' do
        subject.collect

        sample = Sample.all.first

        expect(sample.machine_sample.cpu_usage_percent).to eq(metric_value)
        expect(sample.machine_sample.memory_megabytes).to eq(metric_value)
      end
    end
  end
end