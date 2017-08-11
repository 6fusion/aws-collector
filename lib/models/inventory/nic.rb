require "hash_extensions"

class Nic
  include Mongoid::Document

  field :custom_id, type: String
  field :name, type: String
  field :state, type: String
  field :status, type: String, default: :Active
  field :kind, type: String, default: 'LAN'
  field :speed_bits_per_second, type: Integer, default: lambda{ kind.eql?('WAN') ?
                                                                  PropertyHelper.default_wan_io.to_i :
                                                                  PropertyHelper.default_lan_io.to_i }


  field :tags, type: Array, default: []

  validates :custom_id, presence: true

  def self.default_wan_hash
    { name: 'default_WAN',
      custom_id: 'default_WAN',
      state: 'active',
      kind: 'WAN',
      speed_bits_per_second: PropertyHelper.default_wan_io.to_i }
  end

  def infrastructure_json
    {
      custom_id: custom_id,
      name: name,
      state: state,
      status: status,
      tags: tags,
      kind: kind,
      speed_bits_per_second: speed_bits_per_second
    }
  end

  def to_payload
    {
      custom_id: custom_id,
      name: name,
      status: status,
      kind: kind,
      speed_bits_per_second: speed_bits_per_second
    }
  end

  def different_from_old?(old_nic)
    json = to_payload
    [:custom_id, :name, :status].any? { |key| json[key] != old_nic[key] }
  end
end
