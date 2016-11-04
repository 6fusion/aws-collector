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
  field :status, type: String, default: :active
  field :tags, type: Hash, default: {}

  field :cost_per_hour, type: String

  validates :custom_id, :type, presence: true

  def infrastructure_json
    {
      custom_id: custom_id,
      name: name,
      type: type,
      instance_store_type: instance_store_type,
      instance_stores_count: instance_stores_count,
      size_gib: size_gib,
      storage_bytes: bytes,
      iops: iops,
      state: state,
      status: status,
      tags: tags&.join || [],
      cost_per_hour: cost
    }
  end

  def to_payload
    {
      custom_id: custom_id,
      name: name,
      status: status,
      storage_bytes: bytes
    }
  end

  def bytes
    size_gib * 1_073_741_824.0
  end

  def cost
    (cost_per_hour || 0).to_f
  end
end
