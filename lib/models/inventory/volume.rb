class Volume
  include Mongoid::Document

  field :custom_id, type: String
  field :name, type: String
  field :type, type: String

  field :size_gib, type: Float
  field :iops, type: Integer

  field :state, type: String
  field :tags, type: Hash

  validates :custom_id, :type, :state, presence: true
end