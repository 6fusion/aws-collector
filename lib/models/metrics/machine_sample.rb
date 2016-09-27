class MachineSample
  include Mongoid::Document
  include DefaultIfNil

  field :custom_id, type: String
  field :cpu_usage_percent, type: Integer, default: 0
  field :memory_megabytes, type: Integer, default: 0

  validates :custom_id, presence: true
  validates :cpu_usage_percent, :memory_megabytes,
            presence: true,
            numericality: { greater_than_or_equal_to: 0 }

  embedded_in :sample
end