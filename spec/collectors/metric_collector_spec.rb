require 'collectors/metric_collector'
require 'shared_context'
require 'aws-sdk'

RSpec.describe MetricCollector do
  include_context 'shared collectors context'

  before(:example) { Mongoid.purge! }

  context 'with metric datapoints available for metric' do
    let (:data_point) { double(average: 1, timestamp: Time.new) }
    let (:statistics) { double(datapoints: [data_point]) }


    context 'with metric name = CPUUtilization' do
      let (:metric_name) { 'CPUUtilization' }

      it 'processes and stores CPUUtilization metric in mongo' do
        expect(cw_client).to receive(:get_metric_statistics).
            with(hash_including(metric_name: metric_name)).
            and_return(statistics)

        subject.process_ec2_metric(metric_name, {})

        stored_instance = EC2Instance.find_by(id: instance.instance_id)
        stored_metrics = stored_instance.metrics
        expect(stored_metrics.size).to eq(1)

        stored_data_point = stored_metrics.first.metric_data_points.first
        expect(stored_data_point.value).to eq(data_point.average)
        expect(stored_data_point.timestamp.to_s).to eq(data_point.timestamp.to_s)
      end
    end

    context 'with metric name = DiskWriteBytes and instance root device type = ebs' do
      let (:metric_name) { 'DiskWriteBytes' }

      before(:each) do
        allow(instance).to receive(:root_device_type).and_return('ebs')
      end

      it 'doesn\'t process and store the metric in mongo' do
        expect(cw_client).to receive(:get_metric_statistics).never

        subject.process_ec2_metric(metric_name, {})

        expect(EC2Instance.where(id: instance.instance_id).present?).to be_falsey
      end
    end
  end
end