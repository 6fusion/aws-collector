class Inventory
  include Mongoid::Document

  field :organization_id, type: String
  field :name, type: String
  field :tags, type: Array, default: []
  field :cr_date, type: DateTime, default: Time.new

  validates :organization_id, :name, presence: true

  embeds_many :hosts
end