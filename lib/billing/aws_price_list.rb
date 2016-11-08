module AWS
  module PriceList
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

    def self.find(criteria)
      product = Product.where(criteria).first

      unless product
        puts "Product does not exist: #{criteria}"
        return 0
      end

      term = Term.find_by(id: "AmazonEC2:OnDemand:#{product.sku}").data
      decode(term).first.last["priceDimensions"].first.last["pricePerUnit"].first.last
    end

    def self.decode(json)
      JSON.parse(json.to_json.gsub(/%2E/, "."))
    end

    module EC2
      def self.cost_per_hour(options)
        region = options[:region]
        instance_type = options[:instance_type]
        operating_system = options[:operating_system]
        ebs_optimized = options[:ebs_optimized]
        tenancy = options[:tenancy]

        criteria = {
          "offer_code" => "AmazonEC2",
          "product_family" => "Compute Instance",
          "attr.preInstalledSw" => "NA",
          "attr.location" => REGIONS[region],
          "attr.instanceType" => instance_type,
          "attr.operatingSystem" => operating_system,
          "attr.tenancy" => tenancy == "default" ? "Shared" : tenancy
        }

        criteria["attr.ebsOptimized"] = "Yes" if ebs_optimized
        criteria["attr.licenseModel"] = "License Included" if operating_system == "Windows"

        AWS::PriceList.find(criteria)
      end
    end

    module EBS
      def self.cost_per_hour(options)
        region = options[:region]
        ebs_type = options[:type]

        case ebs_type
          when "standard"
            ebs_type = "$"
          when "io1"
            ebs_type = ".piops"
          else
            ebs_type = ".#{ebs_type}"
        end

        criteria = {
          "offer_code" => "AmazonEC2",
          "product_family" => "Storage",
          "attr.location" => REGIONS[region],
          "attr.usagetype" => /EBS:VolumeUsage#{ebs_type}/i
        }

        AWS::PriceList.find(criteria)
      end
    end
  end
end
