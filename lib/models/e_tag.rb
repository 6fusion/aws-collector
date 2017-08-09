

class ETag
  include Mongoid::Document
  field :etag, type: String
  field :name, type: String

  index({ name: 1 })
end
