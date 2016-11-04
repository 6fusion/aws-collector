require "hash_extensions"

class Nic
  include Mongoid::Document

  field :custom_id, type: String
  field :name, type: String
  field :state, type: String
  field :status, type: String, default: :active

  field :tags, type: Hash, default: {}

  validates :custom_id, presence: true

  def infrastructure_json
    {
      custom_id: custom_id,
      name: name,
      state: state,
      status: status,
      tags: tags&.join || []
    }
  end

  def to_payload
    {
      custom_id: custom_id,
      name: name,
      status: status,
      kind: :WAN
    }
  end
end
