require 'aws_helper'

class MetricCollector
  include AWSHelper

  def initialize(options)
    @options = {
        start_time: options[:start_time],
        end_time: options[:end_time],
        period: 5.minutes,
        statistics: ['Average']
    }
    @timestamps = Set.new
  end

  def collect
    inventory = Inventory.order_by(created_at: :desc).first
    inventory.hosts.each { |host| collect_samples(host) }
  end

  private

  def collect_samples(host)
    custom_id = host.custom_id
    region = host.region
    platform = host.platform

    save(machine: collect_machine(custom_id, region, platform),
         nics: collect_nics(custom_id, region),
         disks: collect_disks(host))
  end

  def collect_machine(custom_id, region, platform)
    memory_namespace = platform ? 'Windows/Default' : 'System/Linux'
    cpu_options = ec2_options('CPUUtilization', custom_id)
    memory_options = ec2_options('Memory', custom_id, memory_namespace)
    {
        id: custom_id,
        cpu_usage: datapoints(region, cpu_options),
        memory_megabytes: datapoints(region, memory_options)
    }
  end

  def collect_nics(custom_id, region)
    {
        id: "united_network_of_instance_#{custom_id}",
        network_in: datapoints(region, ec2_options('NetworkIn', custom_id)),
        network_out: datapoints(region, ec2_options('NetworkOut', custom_id))
    }
  end

  def collect_disks(host)
    disk_samples = []
    region = host.region

    host.disks.each do |disk|
      metrics = disk.type == 'instance_store' ?
          collect_instance_stores(host.custom_id, region) :
          collect_ebs_volumes(disk.custom_id, region)
      disk_samples.push(metrics)
    end

    disk_samples
  end

  def collect_ebs_volumes(custom_id, region)
    {
        id: custom_id,
        read: datapoints(region, ebs_options('VolumeReadBytes', custom_id)),
        write: datapoints(region, ebs_options('VolumeWriteBytes', custom_id))
    }
  end

  def collect_instance_stores(custom_id, region)
    {
        id: "united_instance_store_of_instance_#{custom_id}",
        read: datapoints(region, ec2_options('DiskReadBytes', custom_id)),
        write: datapoints(region, ec2_options('DiskWriteBytes', custom_id))
    }
  end

  def save(samples)
    machine = samples[:machine]
    nics = samples[:nics]
    disks = samples[:disks]

    cpu_usage = machine[:cpu_usage]
    memory_megabytes = machine[:memory_megabytes]
    network_in = nics[:network_in]
    network_out = nics[:network_out]
    network_id = nics[:id]

    @timestamps.each do |time|
      machine_sample =
          MachineSample.new(custom_id: machine[:id],
                            cpu_usage_percent: cpu_usage[time],
                            memory_megabytes: memory_megabytes[time])
      nic_sample =
          NicSample.new(custom_id: network_id,
                        receive_bytes_per_second: network_in[time],
                        transmit_bytes_per_second: network_out[time])

      disk_sample = disks.collect do |disk|
        DiskSample.new(
            custom_id: disk[:id],
            usage_bytes: 0, #TODO gather this metric
            read_bytes_per_second: disk[:read][time],
            write_bytes_per_second: disk[:write][time]
        )
      end

      Sample.new(
          start_time: @options[:start_time],
          end_time: @options[:end_time],
          machine_sample: machine_sample,
          nic_sample: nic_sample,
          disk_samples: disk_sample
      ).save!
    end
  end

  def ec2_options(metric_name, custom_id, namespace='AWS/EC2')
    {
        dimensions: [name: 'InstanceId', value: custom_id],
        metric_name: metric_name,
        namespace: namespace
    }.merge(@options)
  end

  def ebs_options(metric_name, custom_id)
    {
        dimensions: [name: 'VolumeId', value: custom_id],
        metric_name: metric_name,
        namespace: 'AWS/EBS'
    }.merge(@options)
  end

  def datapoints(region, options)
    client = Clients.cloud_watch(region)
    datapoints = client.get_metric_statistics(options).data.datapoints

    values = datapoints.collect do |datapoint|
      timestamp = datapoint.timestamp
      @timestamps.add(timestamp)
      [timestamp, datapoint.average]
    end

    Hash[values]
  end
end