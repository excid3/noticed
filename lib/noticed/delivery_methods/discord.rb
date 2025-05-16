module Noticed
  module DeliveryMethods
    class Discord < BulkDeliveryMethod
      required_options :json, :url

      def deliver
        post_request evaluate_option(:url), headers: evaluate_option(:headers), json: evaluate_option(:json)
      end
    end
  end
end

ActiveSupport.run_load_hooks :noticed_delivery_methods_discord, Noticed::DeliveryMethods::Discord
