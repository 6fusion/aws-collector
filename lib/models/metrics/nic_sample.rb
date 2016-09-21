class NicSample
  include Mongoid::Document

  field :receive_bytes_per_second, type: Integer, default: 0
  field :transmit_bytes_per_second, type: Integer, default: 0

  embedded_in :sample
end