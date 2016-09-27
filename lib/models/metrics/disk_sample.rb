class DiskSample
  include Mongoid::Document
  include DefaultIfNil

  field :custom_id, type: String
  field :usage_bytes, type: Integer, default: 0
  field :read_bytes_per_second, type: Integer, default: 0
  field :write_bytes_per_second, type: Integer, default: 0

  validates :custom_id, presence: true
  validates :usage_bytes, :read_bytes_per_second, :write_bytes_per_second,
            presence: true,
            numericality: { greater_than_or_equal_to: 0 }

  embedded_in :sample

  def to_payload
    {
      id: custom_id,
      usage_bytes: usage_bytes,
      read_bytes_per_second: read_bytes_per_second,
      write_bytes_per_second: write_bytes_per_second
    }
  end
end