class Volume
  include Mongoid::Document

  field :name, type: String
  field :storage_bytes, type: Integer
  field :speed_bits_per_second, type: Integer
  field :cost_per_hour, type: Float

  validates :name,
            :storage_bytes,
            :speed_bits_per_second,
            :cost_per_hour,
            presence: true

  belongs_to :infrastructure

  def to_payload
    {
      name: self.name,
      storage_bytes: self.storage_bytes,
      speed_bits_per_second: self.speed_bits_per_second,
      cost_per_hour: self.cost_per_hour
    }
  end
end