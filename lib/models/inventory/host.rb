require "hash_extensions"

class Host
  include Mongoid::Document

  field :custom_id, type: String
  field :name, type: String
  field :type, type: String
  field :region, type: String
  field :tags, type: Array, default: ['platform:aws', 'type:instance']

  field :state, type: String
  field :status, type: String, default: :poweredOn
  field :monitoring, type: String

  field :memory_gb, type: Integer
  field :network, type: String
  field :platform, type: String

  field :last_sent_metrics_time, type: Time

  field :cost_per_hour, type: String
  field :billing_resource, type: String

  field :device_mappings, type: Hash

  validates :custom_id, :type, :region, :state, :monitoring, :network, presence: true
  validates :memory_gb,
            presence: true,
            numericality: { greater_than_or_equal_to: 0 }

  embeds_one :cpu
  embeds_many :nics
  embeds_many :disks
  embedded_in :inventory

  def infrastructure_json
    {
      custom_id: custom_id,
      name: name,
      type: type,
      region: region,
      tags: tags,
      state: state,
      status: status,
      monitoring: monitoring,
      memory_bytes: memory_bytes,
      network: network,
      platform: platform,
      last_sent_metrics_time: last_sent_metrics_time,
      cpus: [{
        cores: cpu.cores,
        speed_hz: cpu.speed_hz
      }],
      disks: disks.map(&:infrastructure_json),
      nics: nics.map(&:infrastructure_json),
      cost_per_hour: total_cost
    }
  end

  def to_payload
    {
      custom_id: custom_id,
      name: name,
      cpu_count: cpu.cores,
      cpu_speed_hz: cpu.speed_hz,
      memory_bytes: memory_bytes,
      tags: tags,
      status: status,
      disks: disks.map(&:to_payload),
      nics: nics.map(&:to_payload)
    }
  end

  def get_disk_by_id(id)
    disks.map.find { |disk| disk.custom_id == id }
  end

  def total_cost
    cost + disks.sum(&:cost)
  end

  def cost
    (cost_per_hour || 0).to_f
  end

  def memory_bytes
    memory_gb * 1024 * 1024 * 1024
  end

  def different_from_old?(old_host)
    return true if type != old_host[:type]
    json = to_payload
    [:name, :tags, :status].any? { |key| json[key] != old_host[key] }
  end

  def compare_disks(old)
    old_disks = old[:disks] || []

    # Invoke a callback for new and existing disks
    disks.each do |disk|
      old_disk = old_disks.find { |old_disk| old_disk[:custom_id] == disk.custom_id }
      yield(disk, old_disk)
    end

    # Invoke a callback for deleted disks
    old_disks.each do |old_disk|
      yield(nil, old_disk) unless disks.any? { |disk| old_disk[:custom_id] == disk.custom_id }
    end
  end

  def compare_nics(old)
    old_nics = old[:nics] || []

    # Invoke a callback for new and existing nics
    nics.each do |nic|
      old_nic = old_nics.find { |old_nic| old_nic[:custom_id] == nic.custom_id }
      yield(nic, old_nic)
    end

    # Invoke a callback for deleted nics
    old_nics.each do |old_nic|
      yield(nil, old_nic) unless nics.any? { |nic| old_nic[:custom_id] == nic.custom_id }
    end
  end
end
