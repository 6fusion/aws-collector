require 'aws_helper'
require 'logger'

class MetricCollector
  include AWSHelper

  def initialize
    @options = {
        period: 5.minutes,
        statistics: ['Average']
    }
    @timestamps = Set.new
    @logger = ::Logger.new(STDOUT)
    @logger.level = ENV['LOG_LEVEL'] || 'info'
  end

  def collect
    inventory = Inventory.first
    return false unless inventory

    set_time_options(inventory)

    inventory.hosts.each { |host| collect_samples(host) }
    inventory.update_attributes(last_collected_metrics_time: @options[:end_time])
    true
  end

  private
  def set_time_options(inventory)
    interval = CONFIG.scheduler.collect_samples.interval.to_i.minutes

    start_time = inventory.last_collected_metrics_time
    start_time ||= last_sent_metrics_time(inventory)
    start_time ||= Time.now - interval
    end_time = start_time + interval

    @logger.info "Collecting samples for period #{start_time} -> #{end_time}"

    @options[:start_time] = start_time.iso8601
    @options[:end_time] = end_time.iso8601
  end

  def last_sent_metrics_time(inventory)
    meter_response = MeterHttpClient.new.get_infrastructure(inventory.custom_id)
    time = meter_response['hosts']&.first&.send(:[], 'last_sent_metrics_time')
    Time.parse(time) if time
  end

  def collect_samples(host)
    custom_id = host.custom_id
    region = host.region
    platform = host.platform

    save(host,
         machine: collect_machine(custom_id, region, platform),
         nics: collect_nics(custom_id, region),
         disk_usage: collect_disk_space_available(custom_id, region),
         disks: collect_disks(host))
  end

  def collect_machine(custom_id, region, platform)
    memory_namespace = platform == 'Linux' ? 'System/Linux' : 'Windows/Default'
    cpu_options = ec2_options('CPUUtilization', custom_id)
    memory_options = ec2_options('MemoryUsed', custom_id, memory_namespace)
    {
        id: custom_id,
        cpu_usage: datapoints(region, cpu_options),
        memory_megabytes: datapoints(region, memory_options)
    }
  end

  def collect_disk_space_available(custom_id, region)
    disk_usage = linux_fs_dimensions(custom_id, region).collect do |dimension|
      options = disk_space_available_options(custom_id, dimension, region)
      [dimension, datapoints(region, options)]
    end
    Hash[disk_usage]
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

  def memory_or_fallback(memory, host)
    if memory.nil?
      if host.status == :poweredOff
        0
      else
        host.memory_mb
      end
    else
      memory
    end
  end




  def save(host, samples)
    machine = samples[:machine]
    nics = samples[:nics]

    cpu_usage = machine[:cpu_usage]
    memory_megabytes = machine[:memory_megabytes]
    network_in = nics[:network_in]
    network_out = nics[:network_out]
    network_id = nics[:id]

    @timestamps.each do |time|
      machine_sample =
          MachineSample.new(custom_id: machine[:id],
                            cpu_usage_percent: cpu_usage[time],
                            memory_megabytes: memory_or_fallback(memory_megabytes[time], host))
      nic_sample =
          NicSample.new(custom_id: network_id,
                        receive_bytes_per_second: network_in[time],
                        transmit_bytes_per_second: network_out[time])

      disk_sample = disk_samples(host, samples, time)

      Sample.new(
          start_time: @options[:start_time],
          end_time: @options[:end_time],
          machine_sample: machine_sample,
          nic_sample: nic_sample,
          disk_samples: disk_sample
      ).save!
    end
  end

  def disk_samples(host, samples, time)
    disks = samples[:disks]
    disk_usage = samples[:disk_usage]

    disks.collect do |disk|
      space_available = nil
      disk_id = disk[:id]

      mapped_device = host.device_mappings.find { |x| x.last == disk[:id] }
      if mapped_device
        space_available = disk_usage.find do |key, value|
          compare_block_device_names(key, mapped_device.first)
        end
        space_available = space_available.last[time] if space_available
      end

      usage_bytes = space_available.nil? ?
                      host.get_disk_by_id(disk_id)&.bytes :
                      disk_space_used(host.get_disk_by_id(disk_id), space_available)
      @logger.debug "#{Time.now.utc}: #{disk_id}@#{host.custom_id}: usage_bytes: #{usage_bytes}, #{space_available.nil? ? 'host capacity' : 'cloudwatch'}"
      @logger.debug "#{Time.now.utc}: #{disk_id}@#{host.custom_id}: host.status: #{host.status}"
      if host.instance_store_disk&.custom_id == disk_id and (host.status != :poweredOff)
        @logger.debug "#{Time.now.utc}: #{disk_id}@#{host.custom_id}: updating usage_bytes to #{instance_store_usage_bytes(host, disk_usage, time)}"
        usage_bytes = instance_store_usage_bytes(host, disk_usage, time)
      end

      DiskSample.new(
        custom_id: disk_id,
        usage_bytes: usage_bytes,
        read_bytes_per_second: disk[:read][time],
        write_bytes_per_second: disk[:write][time]
      )
    end
  end

  def instance_store_usage_bytes(host, disk_usage, time)
    disk = host.instance_store_disk

    unmatched_disk_metrics = disk_usage.find_all do |mountpath, samples|
      !find_device_mapping_by_mountpath(host, mountpath) && !samples.empty?
    end
    return if unmatched_disk_metrics.empty?

    space_available = 0
    unmatched_disk_metrics.each { |metric| space_available+= metric.last[time] }
    disk_space_used(disk, space_available)
  end

  def disk_space_used(disk, available_db)
    result = disk.bytes - gb_to_bytes(available_db)
    result > 0 ? result : 0 # If script sends bytes instead of GBs - never write negatives
  end

  def gb_to_bytes(size_gib)
    (size_gib * 1_073_741_824).round
  end

  def find_device_mapping_by_mountpath(host, mountpath)
    host.device_mappings.find { |m| compare_block_device_names(m.first, mountpath) }
  end

  def ec2_options(metric_name, custom_id, namespace='AWS/EC2')
    {
        dimensions: [name: 'InstanceId', value: custom_id],
        metric_name: metric_name,
        namespace: namespace
    }
  end

  def ebs_options(metric_name, custom_id)
    {
        dimensions: [name: 'VolumeId', value: custom_id],
        metric_name: metric_name,
        namespace: 'AWS/EBS'
    }
  end

  def disk_space_available_options(custom_id, fs_dimension, region)
    mount_path_dimensions = linux_mountpath_dimensions(custom_id, region).map do |dimension|
      { name: 'MountPath', value: dimension }
    end

    {
      dimensions: [
        { name: 'InstanceId', value: custom_id },
        { name: 'Filesystem', value: fs_dimension },
      ] + mount_path_dimensions,
      metric_name: "DiskSpaceAvailable",
      namespace: "System/Linux"
    }
  end

  def linux_fs_dimensions(custom_id, region)
    linux_space_available_dimensions(custom_id, region, "Filesystem")
  end

  def linux_mountpath_dimensions(custom_id, region)
    linux_space_available_dimensions(custom_id, region, "MountPath")
  end

  def linux_space_available_dimensions(custom_id, region, dimension)
    client = Clients.cloud_watch(region)
    metrics = client.list_metrics(
      namespace: "System/Linux",
      metric_name: "DiskSpaceAvailable",
      dimensions: [name: 'InstanceId', value: custom_id]
    )
    metrics[0].collect { |metric| metric.dimensions.find_all { |t| t.name == dimension }.map(&:value) }.flatten.uniq
  end

  def datapoints(region, options)
    options = options.merge(@options)

    client = Clients.cloud_watch(region)
    datapoints = client.get_metric_statistics(options).data.datapoints
    @logger.debug "#{Time.now.utc}: datapoints returned for #{options}:"
    @logger.debug "#{Time.now.utc}: #{datapoints.inspect}"
    values = datapoints.collect do |datapoint|
      timestamp = datapoint.timestamp
      @timestamps.add(timestamp)
      [timestamp, datapoint.average]
    end

    Hash[values]
  end

  def compare_block_device_names(n1, n2)
    n1_parts = n1.split("/")
    n2_parts = n2.split("/")

    return false if n1_parts.size != n2_parts.size
    return false if n1_parts[0..-2] != n2_parts[0..-2]

    n1_suffix = n1_parts[-1].sub(/[0-9]+/,'')
    n2_suffix = n2_parts[-1].sub(/[0-9]+/,'')

    return true if n1_suffix == n2_suffix
    return true if n1_suffix == n2_suffix.gsub("xv", "s")
    return true if n1_suffix == n2_suffix.gsub("s", "xv")
    false
  end
end
