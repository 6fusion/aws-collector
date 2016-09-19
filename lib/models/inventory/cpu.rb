class Cpu
  include Mongoid::Document

  field :cores,  type: Integer
  field :speed_ghz, type: String

  validates :cores, :speed_ghz, presence: true
end