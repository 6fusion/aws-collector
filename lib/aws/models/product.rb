class Product
  include Mongoid::Document

  before_validation :composite_pk

  field :offer_code, type: String
  field :product_family, type: String
  field :product_id, type: String
  field :sku, type: String
  field :attr, type: Hash

  index("attr.instanceType" => 1)
  index("attr.location" => 1)
  index("attr.operatingSystem" => 1)

  private

  def composite_pk
    self._id = "#{offer_code}:#{product_family}:#{product_id}"
  end
end