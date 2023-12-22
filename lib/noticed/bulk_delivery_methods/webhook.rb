module Noticed
  module BulkDeliveryMethods
    class Webhook < BulkDeliveryMethod
      required_options :url

      def deliver
        Rails.logger.debug(evaluate_option(:json))
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
