class Infrastructure
  include Mongoid::Document

  field :cost_per_hour, type: String
  field :organization_id, type: String
  field :name, type: String
  field :tags, type: Array

  validates :cost_per_hour, :organization_id, :name, :tags, presence: true

  has_many :hosts
  has_many :networks
  has_many :volumes

  has_one :notional_workload
  has_one :constraint

  def to_payload
    {
      cost_per_hour: self.cost_per_hour,
      organization_id: self.organization_id,
      name: self.name,
      tags: self.tags,
      hosts: self.hosts.all.map { |host| host.to_payload },
      networks: self.networks.all.map { |network| network.to_payload },
      volumes: self.volumes.all.map { |network| network.to_payload },
      notional_workload: self.notional_workload.to_payload,
      constraints: { target_utilization_percent: 0, exclude_local_storage: 0 }
    }
  end
end