class ReportRow
  include Mongoid::Document

  field :resource_id, type: String
  field :usage_type, type: String
  field :usage_start_date, type: DateTime
  field :usage_end_date, type: DateTime
  field :description, type: String
  field :cost_per_hour, type: Float

  index({resource_id: 1, usage_type: 1}, { background: true})

end
