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
  field :status, type: String, default: :Active
  field :tags, type: Array, default: []

  field :cost_per_hour, type: String
  field :billing_resource, type: String

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
      tags: tags,
      speed_bits_per_second: PropertyHelper.default_disk_io.to_i,
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
    (size_gib * 1_073_741_824).round
  end

  def cost
    (cost_per_hour || 0).to_f
  end

  def different_from_old?(old_disk)
    json = to_payload
    json.keys.any? { |key| json[key] != old_disk[key] }
  end
end
