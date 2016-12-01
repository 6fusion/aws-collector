require "property_helper"
require "hash_extensions"
require "aws_helper"

class Inventory
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include PropertyHelper

  field :name, type: String, default: AWSHelper::Clients.iam_username
  field :tags, type: Array, default: []
  field :custom_id, type: String, default: AWSHelper::Clients.iam_userid
  field :last_collected_metrics_time, type: Time

  validates :custom_id, :name, presence: true

  embeds_many :hosts
  embeds_many :networks, class_name: "Nic"
  embeds_many :volumes, class_name: "Disk"

  def infrastructure_json(compact = true)
    json = {
      custom_id: custom_id,
      name: name,
      cost_per_hour: total_cost,
      tags: tags,
      hosts: hosts.map(&:infrastructure_json) || [],
      networks: networks.map(&:infrastructure_json) || [],
      volumes: volumes.map(&:infrastructure_json) || [],
      status: :active
    }
    compact ? json.compact_recursive : json
  end

  def total_cost
    hosts.sum(&:total_cost)
  end

  def different_from_old?(old)
    json = infrastructure_json
    infrastructure_json(false).keys.any? { |key| json[key] != old[key] }
  end

  def compare_hosts(old)
    old_hosts = old[:hosts] || []

    # Invoke a callback for new and existing hosts
    hosts.each do |host|
      old_host = old_hosts.find { |old_host| old_host[:custom_id] == host.custom_id }
      yield(host, old_host)
    end

    # Invoke a callback for deleted hosts
    old_hosts.each do |old_host|
      yield(nil, old_host) unless hosts.any? { |host| old_host[:custom_id] == host.custom_id }
    end
  end
end
