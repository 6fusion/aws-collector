class Term
  include Mongoid::Document

  before_validation :composite_pk

  field :offer_code, type: String
  field :term_type, type: String
  field :term_id, type: String
  field :data, type: Hash

  private

  def composite_pk
    self._id = "#{offer_code}:#{term_type}:#{term_id}"
  end
end