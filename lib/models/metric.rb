class Metric
  include Mongoid::Document

  field :name, type: String
  field :namespace, type: String
  field :start_time, type: Time
  field :end_time, type: Time
  field :device_id, type: String

  validates :name, :namespace, :start_time, :end_time, :device_id,
            presence: true

  has_many :metric_data_points
end