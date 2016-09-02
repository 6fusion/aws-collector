require 'aws_helper'

class MetricCollector
  include AWSHelper

  def process_ec2_metric(metric_name, options)
    process_metrics(metric_name, Ec2InstanceMetricCollector, options)
  end

  def process_ebs_metric(metric_name, options)
    process_metrics(metric_name, EbsInstanceMetricCollector, options)
  end

  private

  def process_metrics(metric_name, metric_collector, options)
    each_instance do |instance|
      metric_collector.new(metric_name, instance, options).process
    end
  end

  def each_instance
    InfrastructureCollector.new.instances.each do |instance|
      yield(instance)
    end
  end
end