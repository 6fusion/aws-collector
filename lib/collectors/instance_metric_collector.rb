require 'aws_helper'

class InstanceMetricCollector
  include AWSHelper

  def initialize(metric_name, instance, options)
    @metric_name = metric_name
    @instance = instance
    @options = merge_options(metric_name, options)
    @region = instance.client.config.region
    @instance_id = instance.instance_id
    @ec2_instance = EC2Instance.find_or_initialize_by(id: @instance_id)
    @cw_client = Clients.cloud_watch(@region)
  end

  def add_metric(statistics, metric_attrs)
    metric = @ec2_instance.metrics.find_or_initialize_by(metric_attrs)
    metric.metric_data_points.push(datapoints(statistics))
  end

  def save
    @ec2_instance.save!
  end

  private

  def merge_options(metric_name, options)
    period = CONFIG.collectors.metric.period
    {
        metric_name: metric_name,
        period: period,
        statistics: ['Average']
    }.merge(options)
  end

  def datapoints(statistic)
    statistic.datapoints.collect do |data_point|
      MetricDataPoint.new(value: data_point.average, timestamp: data_point.timestamp)
    end
  end
end