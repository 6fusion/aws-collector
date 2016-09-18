class NotionalWorkload
  include Mongoid::Document

  field :namespace, type: String
  field :name, type: String
  field :version, type: Integer

  validates :namespace, :name, :version, presence: true

  belongs_to :infrastructure

  def to_payload
    {
      namespace: self.namespace,
      name: self.name,
      version: self.version
    }
  end
end