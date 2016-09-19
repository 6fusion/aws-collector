require 'collectors/metric_collector'
require 'shared_context'
require 'aws-sdk'

RSpec.describe MetricCollector do
  include_context 'shared collectors context'

  before(:example) { Mongoid.purge! }

  context 'with metric datapoints available for metric' do
    let (:data_point) { double(average: 1, timestamp: Time.new) }
    let (:statistics) { double(datapoints: [data_point]) }
    let (:start_time) { '2016-09-18T16:11:03+03:00' }

    it 'processes and stores metrics in mongo' do
      allow(cw_client).to receive(:get_metric_statistics).and_return(statistics)

      subject.process(start_time: start_time)

      stored_metrics = MetricsCollection.find_by(start_time: start_time)
      expect(stored_metrics).to be_truthy

      stored_metric_value = stored_metrics.metric_values.first
      expect(stored_metric_value.value).to eq(data_point.average)
      expect(stored_metric_value.timestamp.to_s).to eq(data_point.timestamp.to_s)
    end
  end
end