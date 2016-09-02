class Metric
  include Mongoid::Document

  field :name, type: String
  field :namespace, type: String
  field :start_time, type: Time
  field :end_time, type: Time
  field :device_id, type: String

  validates_presence_of :name, :namespace, :start_time, :end_time, :device_id

  has_many :metric_data_points
end