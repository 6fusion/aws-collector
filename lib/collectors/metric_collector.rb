require 'aws_helper'

class MetricCollector
  include AWSHelper

  DEFAULT_OPTIONS = {
    namespace: 'AWS/EC2',
    statistics: ['Average']
  }

  def process_metrics(metric_name, options)
    InfrastructureCollector.new.instances.each do |instance|
      region = instance.client.config.region
      instance_id = instance.instance_id
      merged_options = merge_options(metric_name, options, instance_id)
      statistics = Clients.cloud_watch(region).get_metric_statistics(merged_options)

      metric = Metric.new(name: metric_name, metric_data_points: datapoints(statistics))

      ec2_instance = EC2Instance.find_or_initialize_by(id: instance_id)
      ec2_instance.metrics << metric
      ec2_instance.save!
    end
  end

  private

  def merge_options(metric_name, options, instance_id)
    dimensions = [name: 'InstanceId', value: instance_id]
    period = CONFIG.collectors.metric.period
    DEFAULT_OPTIONS.
      merge(metric_name: metric_name, dimensions: dimensions, period: period).
      merge(options)
  end

  def datapoints(statistic)
    statistic.datapoints.collect do |data_point|
      MetricDataPoint.new(value: data_point.average, timestamp: data_point.timestamp)
    end
  end
end