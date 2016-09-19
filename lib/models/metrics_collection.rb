class MetricsCollection
  include Mongoid::Document

  field :start_time, type: Time

  validates_presence_of :start_time

  embeds_many :metric_values
end