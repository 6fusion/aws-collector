require "hash_extensions"

class Disk
  include Mongoid::Document

  field :custom_id, type: String
  field :name, type: String
  field :type, type: String
  field :instance_store_type, type: String
  field :instance_stores_count, type: Integer

  field :size_gib, type: Float
  field :iops, type: Integer

  field :state, type: String
  field :tags, type: Hash, default: {}

  validates :custom_id, :type, presence: true

  def infrastructure_json
    {
      custom_id: custom_id,
      name: name,
      type: type,
      instance_store_type: instance_store_type,
      instance_stores_count: instance_stores_count,
      size_gib: size_gib,
      iops: iops,
      state: state,
      tags: tags.join.nil_if_empty
    }.compact
  end

  def to_payload
    {
      custom_id: custom_id,
      name: name,
      storage_bytes: bytes
    }.compact
  end

  def bytes
    size_gib * 1_073_741_824.0
  end
end
