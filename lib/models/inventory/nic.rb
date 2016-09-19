class Nic
  include Mongoid::Document

  field :custom_id, type: String
  field :description, type: String
  field :status, type: String

  validates :custom_id, presence: true
end