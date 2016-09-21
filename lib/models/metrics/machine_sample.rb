class MachineSample
  include Mongoid::Document

  field :cpu_usage_percent, type: Integer, default: 0
  field :memory_bytes, type: Integer, default: 0

  embedded_in :sample
end