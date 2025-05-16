module Noticed
  module BulkDeliveryMethods
    class Discord < BulkDeliveryMethod
      required_options :json, :url

      def deliver
        post_request evaluate_option(:url), headers: evaluate_option(:headers), json: evaluate_option(:json)
      end
    end
  end
end

ActiveSupport.run_load_hooks :noticed_bulk_delivery_methods_discord, Noticed::BulkDeliveryMethods::Discord
