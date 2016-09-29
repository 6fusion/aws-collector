class Sample
  include Mongoid::Document

  field :start_time, type: Time
  field :end_time, type: Time

  validates :start_time, :end_time, presence: true

  embeds_one :machine_sample, cascade_callbacks: true
  embeds_one :nic_sample, cascade_callbacks: true
  embeds_many :disk_samples, cascade_callbacks: true

  def to_payload
    {
      start_time: start_time.utc.iso8601,
      end_time: end_time.utc.iso8601,
      machine: machine_sample.to_payload,
      nics: [nic_sample.to_payload],
      disks: disk_samples.all.map { |disk_sample| disk_sample.to_payload }
    }
  end
end