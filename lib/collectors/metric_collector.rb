require 'aws_helper'

class MetricCollector
  include AWSHelper

  METRICS = {
      cpu_usage_percent: 'CPUUtilization',
      read_bytes_per_second: 'DiskReadBytes',
      write_bytes_per_second: 'DiskWriteBytes',
      receive_bytes_per_second: 'NetworkIn',
      transmit_bytes_per_second: 'NetworkOut'
  }
  EC2_NAMESPACE = 'AWS/EC2'
  EBS_NAMESPACE = 'AWS/EBS'
  AGGREGATION_MODE = 'Average'
  PERIOD = 60

  def process(metric_name, options)
    cw_options = merge_options(metric_name, options)
    each_instance do |instance|
      cw_options[:dimensions] = [name: 'InstanceId', value: instance.instance_id]
      cw_client = Clients.cloud_watch(instance.client.config.region)

      if is_disk_metric?(metric_name)
        process_ebs(metric_name, cw_options, cw_client, instance)
        next if is_root_ebs?(instance)
      end

      statistics = cw_client.get_metric_statistics(cw_options)
      save(metric_name, statistics, cw_options)
    end
  end

  private
  def process_ebs(metric_name, options, cw_client, instance)
    cw_options = options.clone
    cw_options[:metric_name].sub!('Disk', 'Volume')
    cw_options[:namespace] = EBS_NAMESPACE

    instance.block_device_mappings.each do |block|
      volume_id = block.ebs.volume_id
      cw_options[:dimensions] = [name: 'VolumeId', value: volume_id]
      statistics = cw_client.get_metric_statistics(cw_options)
      save(metric_name, statistics, cw_options)
    end
  end

  def save(metric_name, statistics, options)
    metric = Metric.find_or_create_by(
        name: metric_name,
        device_id: options[:dimensions].first[:value],
        start_time: options[:start_time],
        end_time: options[:end_time],
        namespace: options[:namespace])
    metric.metric_data_points = datapoints(statistics)
    metric.save!
  end

  def merge_options(metric_name, options)
    {
        namespace: EC2_NAMESPACE,
        metric_name: METRICS[metric_name.to_sym],
        period: PERIOD,
        statistics: [AGGREGATION_MODE]
    }.merge!(options)
  end

  def datapoints(statistic)
    statistic.datapoints.collect do |data_point|
      MetricDataPoint.new(value: data_point.average, timestamp: data_point.timestamp)
    end
  end

  def is_disk_metric?(metric_name)
    metric_name.start_with?('read', 'write')
  end

  def is_root_ebs?(instance)
    instance.root_device_type == 'ebs'
  end

  def each_instance
    InfrastructureCollector.new.instances.each do |instance|
      yield(instance)
    end
  end
end