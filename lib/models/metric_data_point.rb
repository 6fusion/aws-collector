class MetricDataPoint
  include Mongoid::Document

  field :value, type: Float
  field :timestamp, type: Time

  validates_presence_of :value, :timestamp

  belongs_to :metric
end