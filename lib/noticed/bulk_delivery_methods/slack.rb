module Noticed
  module BulkDeliveryMethods
    class Slack < BulkDeliveryMethod
      include SlackDelivery
    end
  end
end

ActiveSupport.run_load_hooks :noticed_bulk_delivery_methods_slack, Noticed::BulkDeliveryMethods::Slack
