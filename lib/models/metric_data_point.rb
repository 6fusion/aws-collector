class MetricDataPoint
  include Mongoid::Document

  field :value, type: Float
  field :timestamp, type: Time

  validates :value, :timestamp, presence: true

  belongs_to :metric
end