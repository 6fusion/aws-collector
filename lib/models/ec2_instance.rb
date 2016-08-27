class EC2Instance
  include Mongoid::Document

  field :id, type: String

  embeds_many :metrics
end