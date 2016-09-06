module AWS
  module PriceList
    module EC2
      def self.on_demand(options = {})
        decode price_details("OnDemand", options)
      end

      def self.reserved(options = {})
        decode price_details("Reserved", options)
      end

      private

      def self.price_details(term_type, options)
        products(options).collect do |product|
          Term.find_by(id: "AmazonEC2:#{term_type}:#{product.sku}").data
        end
      end

      def self.products(options)
        options.keys.each do |key|
          options.store("attr.#{key}", options.delete(key))
        end

        Product.where(options)
      end

      def self.decode(json)
        JSON.parse(json.to_json.gsub(/%2E/, "."))
      end
    end
  end
end
