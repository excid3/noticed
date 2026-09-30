module Noticed
  module DeliveryMethods
    class Webhook < DeliveryMethod
      include WebhookDelivery
    end
  end
end

ActiveSupport.run_load_hooks :noticed_delivery_methods_webhook, Noticed::DeliveryMethods::Webhook
