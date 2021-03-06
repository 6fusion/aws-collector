require "hash_extensions"

class Nic
  include Mongoid::Document

  field :custom_id, type: String
  field :name, type: String
  field :state, type: String
  field :status, type: String, default: :Active
  field :kind, type: String, default: "LAN"

  field :tags, type: Array, default: []

  validates :custom_id, presence: true

  def infrastructure_json
    {
      custom_id: custom_id,
      name: name,
      state: state,
      status: status,
      tags: tags,
      kind: kind,
      speed_bits_per_second: kind.eql?('LAN') ? PropertyHelper.default_lan_io.to_i : PropertyHelper.default_wan_io.to_i
    }
  end

  def to_payload
    {
      custom_id: custom_id,
      name: name,
      status: status,
      kind: kind
    }
  end

  def different_from_old?(old_nic)
    json = to_payload
    [:custom_id, :name, :status].any? { |key| json[key] != old_nic[key] }
  end
end
