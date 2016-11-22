require "hash_extensions"

class Nic
  include Mongoid::Document

  field :custom_id, type: String
  field :name, type: String
  field :state, type: String

  field :tags, type: Hash, default: {}

  validates :custom_id, presence: true

  def infrastructure_json
    {
      custom_id: custom_id,
      name: name,
      state: state,
      status: "connected",
      tags: tags&.join || []
    }
  end

  def to_payload
    {
      custom_id: custom_id,
      name: name,
      status: "connected",
      kind: :WAN
    }
  end

  def different_from_old?(old_nic)
    json = to_payload
    [:custom_id, :name, :status].any? { |key| json[key] != old_nic[key] }
  end
end
