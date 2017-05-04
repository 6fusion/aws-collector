class InstanceType
  include Mongoid::Document

  field :name,          type: String
  field :cores,         type: Integer
  field :cpu_speed_ghz, type: Float
  field :memory_gb,     type: Float
  field :network,       type: String
end
