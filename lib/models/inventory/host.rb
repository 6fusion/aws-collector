class Host
  include Mongoid::Document

  field :custom_id, type: String
  field :name, type: String
  field :type, type: String
  field :region, type: String
  field :tags, type: Hash

  field :state, type: String
  field :launch_time, type: DateTime
  field :monitoring, type: String

  field :memory_gb, type: Float
  field :network, type: String
  field :platform, type: String
  field :root_device_type, type: String, default: 'instance-store'

  validates :custom_id, :name, :type, :region, :state, :monitoring, :network, presence: true
  validates :memory_gb,
            presence: true,
            numericality: { greater_than_or_equal_to: 0 }

  embeds_one :cpu
  embeds_many :nics
  embeds_many :disks
end