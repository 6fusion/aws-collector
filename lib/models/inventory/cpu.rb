require "hash_extensions"

class Cpu
  include Mongoid::Document

  MICRO_INSTANCE_SPEED_HZ = 3.4

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
    ghz_float = speed_ghz.to_f
    ghz_to_hz(ghz_float == 0 ? MICRO_INSTANCE_SPEED_HZ : ghz_float)
  end

  private

  def ghz_to_hz(ghz)
    ghz * 1000_000_000.0
  end
end
