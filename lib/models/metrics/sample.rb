class Sample
  include Mongoid::Document

  field :start_time, type: Time
  field :end_time, type: Time

  validates :start_time, :end_time, presence: true

  embeds_one :machine_sample, cascade_callbacks: true
  embeds_one :nic_sample, cascade_callbacks: true
  embeds_many :disk_samples, cascade_callbacks: true

  index({ start_time: 1 })

  def to_payload
    {
      start_time: start_time.utc.iso8601,
      end_time: end_time.utc.iso8601,
      machine: machine_sample.to_payload,
      nics: [nic_sample.to_payload],
      disks: disk_samples.all.map { |disk_sample| disk_sample.to_payload }
    }
  end

  def self.latest_start_time
    Sample.desc(:start_time).limit(1).first
  end

  def self.persisted_start_times
    # TODO Compare these using a larger sample set
    # db.samples.explain("executionStats").distinct("start_time")
    # db.samples.aggregate( [ { $group: { _id: "$start_time" } }, { $sort: { _id: -1 } } ], { explain: true } )
    Sample.distinct(:start_time).sort
  end

  def self.group_by_start_time(time)
    Sample.collection.aggregate( [ { "$match": { start_time: time } },
                                   { "$group": { _id: "$start_time" } } ] )
  end

end
