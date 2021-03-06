require "httparty"

module AWS
  module PriceList
    include HTTParty

    base_uri "https://pricing.us-east-1.amazonaws.com"
    format :json

    def self.fetch
      flush
      response = http_get("/offers/v1.0/aws/index.json").to_dot

      begin
        ec2_offer = response.offers["AmazonEC2"]
        persist offer_file(ec2_offer["offerCode"],
                           ec2_offer["currentVersionUrl"]).to_dot
      rescue StandardError => e
        $logger.warn "Skipping persistence of #{offer_code} because of error: #{e.message}"
      end
    end

    private

    def self.offer_file(offer_code, current_version_url)
      $logger.info "Fetching price details for #{offer_code}"
      http_get(current_version_url)
    end

    def self.flush
      $logger.info "Removing old AWS price list API details from DB"
      Product.destroy_all
      Term.destroy_all
    end

    def self.persist(offer_file)
      products(offer_file)
      terms(offer_file)
    end

    def self.products(offer_file)
      offer_file.products.each do |product|
        Product.new(offer_code: offer_file.offerCode,
                    product_family: product.last.productFamily,
                    product_id: product.first,
                    sku: product.last.sku,
                    attr: product.last.attributes).save!
      end
    end

    def self.terms(offer_file)
      offer_file.terms.each do |terms|
        terms.last.each do |data|
          Term.new(offer_code: offer_file.offerCode,
                   term_type: terms.first,
                   term_id: data.first,
                   data: encode(data.last)).save!
        end
      end
    end

    def self.encode(json)
      JSON.parse(json.to_json.gsub(/\./, "%2E"))
    end

    def self.http_get(url, retry_count = 8)
      begin
        get(url)
      rescue
        retry_count -= 1
        $logger.info "Failed to make get request to: #{url} | Retries left: #{retry_count}"
        retry if retry_count >= 0
      end
    end
  end
end
