class Metric
  include Mongoid::Document

  field :name, type: String

  embeds_many :metric_data_points
  embedded_in :ec2_instance
end