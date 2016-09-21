class DiskSample
  include Mongoid::Document

  field :usage_bytes, type: Integer, default: 0
  field :read_bytes_per_second, type: Integer, default: 0
  field :write_bytes_per_second, type: Integer, default: 0

  embedded_in :sample
end