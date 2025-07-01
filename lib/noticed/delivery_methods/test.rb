module Noticed
  module DeliveryMethods
    class Test < DeliveryMethod
      class_attribute :delivered, default: []

      def deliver
        delivered << notification
      end
    end
  end
end

ActiveSupport.run_load_hooks :noticed_delivery_methods_test, Noticed::DeliveryMethods::Test
