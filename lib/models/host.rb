class Host
  include Mongoid::Document

  field :cost_per_hour, type: String
  field :memory_bytes,  type: Integer

  validates :cost_per_hour, presence: true
  validates :memory_bytes,
            presence: true,
            numericality: { greater_than_or_equal_to: 0 }

  has_many :host_cpus
  has_many :host_nics
  has_many :host_disks
  has_many :host_hbas

  belongs_to :infrastructure

  def to_payload
    {
      cost_per_hour: self.cost_per_hour,
      memory_bytes: self.memory_bytes,
      cpus: self.host_cpus.all.map { |cpu| cpu.to_payload },
      nics: self.host_nics.all.map { |nic| nic.to_payload },
      discs: self.host_disks.all.map { |disc| disc.to_payload },
      hbas: self.host_hbas.all.map { |hbas| hbas.to_payload }
    }
  end
end