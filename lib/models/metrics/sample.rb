class Sample
  include Mongoid::Document

  field :start_time, type: Time
  field :end_time, type: Time

  validates :start_time, :end_time, presence: true

  embeds_one :machine_sample
  embeds_one :nic_sample
  embeds_many :disk_samples
end