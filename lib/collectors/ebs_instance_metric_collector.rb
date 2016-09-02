require 'aws_helper'
require 'instance_metric_collector'

class EbsInstanceMetricCollector < InstanceMetricCollector
  def initialize(metric_name, instance, options)
    super
    @options[:namespace] = 'AWS/EBS'
  end

  def process()
    @instance.block_device_mappings.each do |block|
      volume_id = block.ebs.volume_id
      @options[:dimensions] = [name: 'VolumeId', value: volume_id]
      statistics = @cw_client.get_metric_statistics(@options)
      add_metric(statistics, name: @metric_name, volume_id: volume_id)
    end
    save
  end
end