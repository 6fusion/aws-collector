require "hash_extensions"

class Cpu
  include Mongoid::Document

  field :cores, type: Integer
  field :speed_ghz, type: String

  validates :cores, :speed_ghz, presence: true

  def infrastructure_json
    {
      cores: cores,
      speed_ghz: speed_ghz
    }
  end

  def speed_hz
    speed_ghz.to_f * 1000_000_000.0
  end
end
