module AWS
  module PriceList
    module EBS
      REGIONS = {
        "us-east-1" => "US East (N. Virginia)",
        "us-west-2" => "US West (Oregon)",
        "us-west-1" => "US West (N. California)",
        "eu-west-1" => "EU (Ireland)",
        "eu-central-1" => "EU (Frankfurt)",
        "ap-southeast-1" => "Asia Pacific (Singapore)",
        "ap-northeast-1" => "Asia Pacific (Tokyo)",
        "ap-southeast-2" => "Asia Pacific (Sydney)",
        "ap-northeast-2" => "Asia Pacific (Seoul)",
        "ap-south-1" => "Asia Pacific (Mumbai)",
        "sa-east-1" => "South America (São Paulo)"
      }

      def self.cost_per_hour(options)
        region = options[:region]
        ebs_type = options[:type]

        ebs_product = Product.where("offer_code" => "AmazonEC2",
                                    "product_family" => "Storage",
                                    "attr.location" => REGIONS[region],
                                    "attr.usagetype" => /EBS:VolumeUsage.#{ebs_type}/i).first

        raise "EBS product does not exist for region: #{region} and type: #{ebs_type}" unless ebs_product

        term = Term.find_by(id: "AmazonEC2:OnDemand:#{ebs_product.sku}").data
        decode(term).first.last["priceDimensions"].first.last["pricePerUnit"].first.last
      end

      def self.decode(json)
        JSON.parse(json.to_json.gsub(/%2E/, "."))
      end
    end
  end
end
