class MetricValue
  include Mongoid::Document

  field :name, type: String
  field :value, type: Float
  field :device_id, type: String
  field :namespace, type: String
  field :timestamp, type: Time

  validates_presence_of :name,
                        :value,
                        :device_id,
                        :namespace,
                        :timestamp

  embedded_in :metric
end