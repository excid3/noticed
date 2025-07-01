module Noticed
  module BulkDeliveryMethods
    class Test < BulkDeliveryMethod
      class_attribute :delivered, default: []

      def deliver
        delivered << event
      end
    end
  end
end

ActiveSupport.run_load_hooks :noticed_bulk_delivery_methods_test, Noticed::BulkDeliveryMethods::Test
