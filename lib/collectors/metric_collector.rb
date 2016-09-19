require 'aws_helper'

class MetricCollector
  include AWSHelper

  DEFAULT_OPTIONS = {
      period: 300,
      statistics: ['Average']
  }
  METRICS = [
      {
          meter_name: 'cpu_usage_percent',
          aws_ec2_name: 'CPUUtilization'
      },
      {
          meter_name: 'read_bytes_per_second',
          aws_ec2_name: 'DiskReadBytes',
          aws_ebs_name: 'ValueReadBytes',
          is_disk_metric?: true
      },
      {
          meter_name: 'write_bytes_per_second',
          aws_ec2_name: 'DiskWriteBytes',
          aws_ebs_name: 'ValueWriteBytes',
          is_disk_metric?: true
      },
      {
          meter_name: 'receive_bytes_per_second',
          aws_ec2_name: 'NetworkIn'
      },
      {
          meter_name: 'transmit_bytes_per_second',
          aws_ec2_name: 'NetworkOut'
      }
  ]

  def process(options)
    initialize_metric_collection(options[:start_time])

    common_options = merge_common_options(options)
    METRICS.each do |metric|
      process_metric(metric, common_options)
    end
  end

  private
  def process_metric(metric, options)
    each_instance do |instance|
      if metric[:is_disk_metric?]
        process_ebs(metric, options, instance)
        next if is_root_ebs?(instance)
      end

      ec2_options = merge_ec2_options(metric, options)
      ec2_options[:dimensions] = instance_dimension(instance)
      cw_client = Clients.cloud_watch(instance.client.config.region)
      statistics = cw_client.get_metric_statistics(ec2_options)
      save(metric, statistics, ec2_options)
    end
  end

  def initialize_metric_collection(start_time)
    MetricsCollection.destroy_all(start_time: start_time)
    MetricsCollection.create!(start_time: start_time)
  end

  def process_ebs(metric, options, instance)
    cw_client = Clients.cloud_watch(instance.client.config.region)
    ebs_options = merge_ebs_options(metric, options)

    instance.block_device_mappings.each do |block|
      ebs_options[:dimensions] = ebs_volume_dimension(block.ebs)
      statistics = cw_client.get_metric_statistics(ebs_options)
      save(metric, statistics, ebs_options)
    end
  end

  def ebs_volume_dimension(ebs)
    [name: 'VolumeId', value: ebs.volume_id]
  end

  def instance_dimension(instance)
    [name: 'InstanceId', value: instance.instance_id]
  end

  def save(metric, statistics, options)
    collection = MetricsCollection.find_by(start_time: options[:start_time])
    collection.metric_values.push(datapoints(metric, statistics, options))
    collection.save!
  end

  def merge_common_options(options)
    DEFAULT_OPTIONS.merge!(options)
  end

  def merge_ec2_options(metric, options)
    {
        namespace: 'AWS/EC2',
        metric_name: metric[:aws_ec2_name]
    }.merge!(options)
  end

  def merge_ebs_options(metric, options)
    {
        namespace: 'AWS/EBS',
        metric_name: metric[:aws_ebs_name]
    }.merge!(options)
  end

  def datapoints(metric, statistic, options)
    statistic.datapoints.collect do |data_point|
      MetricValue.new(
          name: metric[:meter_name],
          value: data_point.average,
          timestamp: data_point.timestamp,
          device_id: options[:dimensions].first[:value],
          namespace: options[:namespace])
    end
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