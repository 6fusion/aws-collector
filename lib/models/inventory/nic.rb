class Nic
  include Mongoid::Document

  field :custom_id, type: String
  field :name, type: String
  field :state, type: String

  field :tags, type: Hash

  validates :custom_id, presence: true
end