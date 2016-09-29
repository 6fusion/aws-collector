class NicSample
  include Mongoid::Document
  include DefaultIfNil

  field :custom_id, type: String
  field :receive_bytes_per_second, type: Integer, default: 0
  field :transmit_bytes_per_second, type: Integer, default: 0

  validates :custom_id, presence: true
  validates :receive_bytes_per_second, :transmit_bytes_per_second,
            presence: true,
            numericality: { greater_than_or_equal_to: 0 }

  embedded_in :sample

  def to_payload
    {
      id: custom_id,
      receive_bytes_per_second: receive_bytes_per_second,
      transmit_bytes_per_second: transmit_bytes_per_second
    }
  end
end