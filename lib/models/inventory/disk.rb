class Disk
  include Mongoid::Document

  field :custom_id, type: String
  field :name, type: String
  field :type, type: String
  field :isntance_store_type, type: String
  field :isntance_stores_count, type: Integer

  field :size_gib, type: Float
  field :iops, type: Integer

  field :state, type: String
  field :tags, type: Hash

  validates :custom_id, :type, presence: true
end