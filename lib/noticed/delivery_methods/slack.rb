module Noticed
  module DeliveryMethods
    class Slack < DeliveryMethod
      include SlackDelivery
    end
  end
end

ActiveSupport.run_load_hooks :noticed_delivery_methods_slack, Noticed::DeliveryMethods::Slack
