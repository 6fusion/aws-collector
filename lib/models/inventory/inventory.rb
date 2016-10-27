require "property_helper"
require "hash_extensions"

class Inventory
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include PropertyHelper

  field :name, type: String, default: PropertyHelper.infrastructure_name
  field :tags, type: Array, default: {}
  field :custom_id, type: String, default: PropertyHelper.infrastructure_id
  field :synchronized, type: Boolean, default: true
  field :last_collected_metrics_time, type: Time

  validates :custom_id, :name, presence: true

  embeds_many :hosts
  embeds_many :networks, class_name: "Nic"
  embeds_many :volumes, class_name: "Disk"

  def infrastructure_json
    {
      custom_id: custom_id,
      name: name,
      cost_per_hour: 0,
      tags: (tags || []).join.nil_if_empty,
      hosts: hosts.map(&:infrastructure_json) || [],
      networks: networks.map(&:infrastructure_json) || [],
      volumes: volumes.map(&:infrastructure_json) || []
    }.compact
  end
end
