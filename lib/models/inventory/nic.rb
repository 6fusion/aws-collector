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
      tags: tags.join.nil_if_empty
    }.compact
  end

  def to_payload
    {
      custom_id: custom_id,
      name: name,
      kind: :WAN
    }.compact
  end
end
