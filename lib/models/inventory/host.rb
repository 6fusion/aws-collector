require "hash_extensions"

class Host
  include Mongoid::Document

  field :custom_id, type: String
  field :name, type: String
  field :type, type: String
  field :region, type: String
  field :tags, type: Hash

  field :state, type: String
  field :launch_time, type: DateTime
  field :monitoring, type: String

  field :memory_gb, type: Float
  field :network, type: String
  field :platform, type: String

  field :last_sent_metrics_time, type: Time
  field :cost_per_hour, type: String

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
      tags: tags.join.nil_if_empty,
      state: state,
      launch_time: launch_time,
      monitoring: monitoring,
      memory_gb: memory_gb,
      network: network,
      platform: platform,
      last_sent_metrics_time: last_sent_metrics_time,
      cpu: cpu.infrastructure_json,
      disks: disks.map(&:infrastructure_json),
      nics: nics.map(&:infrastructure_json),
      cost_per_hour: total_cost
    }.compact
  end

  def to_payload
    {
      custom_id: custom_id,
      name: name,
      cpu_count: cpu.cores,
      cpu_speed_hz: cpu.speed_hz,
      tags: tags.join.nil_if_empty,
      status: state,
      disks: disks.map(&:to_payload),
      nics: nics.map(&:to_payload)
    }.compact
  end

  def total_cost
    cost + disks.sum(&:cost)
  end

  def cost
    (cost_per_hour || 0).to_f
  end
end
