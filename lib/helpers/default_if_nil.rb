require 'active_support/concern'

module DefaultIfNil
  extend ActiveSupport::Concern

  included do
    before_validation do
      attributes.each do |attr_name, attr_value|
        next if attr_value
        attributes[attr_name] = fields[attr_name].default_val
      end
    end
  end
end