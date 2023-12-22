module Noticed
  module DeliveryMethods
    class VonageSms < DeliveryMethod
      DEFAULT_URL = "https://rest.nexmo.com/sms/json"

      required_options :json

      def deliver
        response = post_request url, headers: evaluate_option(:headers), json: evaluate_option(:json)
        raise ResponseUnsuccessful.new(response) if JSON.parse(response.body).dig("messages", 0, "status") != "0"
      end

      def url
        evaluate_option(:url) || DEFAULT_URL
      end
    end
  end
end
