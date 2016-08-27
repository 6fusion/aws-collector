class MetricDataPoint
  include Mongoid::Document

  field :value, type: Float
  field :timestamp, type: Time

  embedded_in :metric
end