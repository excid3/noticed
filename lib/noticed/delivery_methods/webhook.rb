module Noticed
  module DeliveryMethods
    class Webhook < DeliveryMethod
      required_options :url

      def deliver
        post_request(
          evaluate_option(:url),
          basic_auth: evaluate_option(:basic_auth),
          headers: evaluate_option(:headers),
          json: evaluate_option(:json),
          form: evaluate_option(:form)
        )
      end
    end
  end
end
