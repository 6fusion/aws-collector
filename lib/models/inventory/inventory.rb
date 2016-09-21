class Inventory
  include Mongoid::Document
  include Mongoid::Timestamps::Created

  field :organization_id, type: String
  field :name, type: String
  field :tags, type: Array, default: []

  validates :organization_id, :name, presence: true

  embeds_many :hosts
  embeds_many :networks, class_name: "Nic"
  embeds_many :volumes, class_name: "Disk"
end