require "hash_extensions"

class Nic
  include Mongoid::Document

  field :custom_id, type: String
  field :name, type: String
  field :state, type: String

  field :tags, type: Array, default: []

  validates :custom_id, presence: true

  def infrastructure_json(kind=:LAN)
    {
      custom_id: custom_id,
      name: name,
      state: state,
      status: "connected",
      tags: tags,
      kind: kind
      speed_bits_per_second: kind.eql?(:LAN) ? PropertyHelper.default_lan_io : PropertyHelper.default_wan_io
    }
  end

  def to_payload
    {
      custom_id: custom_id,
      name: name,
      status: "connected",
      kind: :LAN
    }
  end

  def different_from_old?(old_nic)
    json = to_payload
    [:custom_id, :name, :status].any? { |key| json[key] != old_nic[key] }
  end
end
