require 'collectors/metric_collector'
require 'shared_context'
require 'aws-sdk'

RSpec.describe MetricCollector do
  include_context 'shared collectors context'

  before(:example) { Mongoid.purge! }

  context 'with metric datapoints available for metric' do
    let (:data_point) { double(average: 1, timestamp: Time.new) }
    let (:statistics) { double(datapoints: [data_point]) }

    context 'with metric name = cpu_usage_percent' do
      let (:aws_metric_name) { 'CPUUtilization' }

      it 'processes and stores CPUUtilization metric in mongo' do
        expect(cw_client).to receive(:get_metric_statistics).
            with(hash_including(metric_name: aws_metric_name)).
            and_return(statistics)

        subject.process('cpu_usage_percent', {})

        stored_metrics = Metric.find_by(device_id: instance.instance_id)
        expect(stored_metrics).to be_truthy

        stored_data_point = stored_metrics.metric_data_points.first
        expect(stored_data_point.value).to eq(data_point.average)
        expect(stored_data_point.timestamp.to_s).to eq(data_point.timestamp.to_s)
      end
    end

    context 'with metric name = write_bytes_per_second and instance root device type = ebs' do
      let (:aws_metric_name) { 'VolumeWriteBytes' }
      let (:volume_id) { '_volume_id_1'}

      before(:each) do
        allow(instance).to receive(:root_device_type).and_return('ebs')
        allow(instance).to receive(:block_device_mappings).and_return(
            [
                double(ebs: double(volume_id: volume_id))
            ])
      end

      it 'receives metrics from EBS and not from EC2' do
        expect(cw_client).to receive(:get_metric_statistics).
            with(hash_including(namespace: 'AWS/EC2')).never
        expect(cw_client).to receive(:get_metric_statistics).
            with(hash_including(namespace: 'AWS/EBS', metric_name: aws_metric_name)).
            and_return(statistics)

        subject.process('write_bytes_per_second', {})

        stored_metrics = Metric.find_by(device_id: volume_id)
        expect(stored_metrics).to be_truthy

        stored_data_point = stored_metrics.metric_data_points.first
        expect(stored_data_point.value).to eq(data_point.average)
        expect(stored_data_point.timestamp.to_s).to eq(data_point.timestamp.to_s)
      end
    end
  end
end