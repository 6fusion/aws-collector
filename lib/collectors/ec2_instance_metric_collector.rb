require 'aws_helper'
require 'instance_metric_collector'

class Ec2InstanceMetricCollector < InstanceMetricCollector
  def initialize(metric_name, instance, options)
    super
    @options[:namespace] = 'AWS/EC2'
    @options[:dimensions] = [name: 'InstanceId', value: @instance_id]
  end

  def process()
    return if is_disk_metric? @metric_name and is_ebs_root? @instance

    statistics = @cw_client.get_metric_statistics(@options)
    add_metric(statistics, name: @metric_name)
    save
  end

  private

  def is_disk_metric?(metric_name)
    metric_name.start_with? 'Disk'
  end

  def is_ebs_root?(instance)
    instance.root_device_type == 'ebs'
  end
end