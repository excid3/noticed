module Noticed
  module BulkDeliveryMethods
    class Webhook < BulkDeliveryMethod
      include WebhookDelivery
    end
  end
end

ActiveSupport.run_load_hooks :noticed_bulk_delivery_methods_webhook, Noticed::BulkDeliveryMethods::Webhook
