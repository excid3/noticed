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
          form: evaluate_option(:form),
          body: evaluate_option(:body)
        )
      end
    end
  end
end

ActiveSupport.run_load_hooks :noticed_delivery_methods_webhook, Noticed::DeliveryMethods::Webhook
