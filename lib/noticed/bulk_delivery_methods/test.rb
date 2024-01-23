module Noticed
  module BulkDeliveryMethods
    class Test < DeliveryMethod
      class_attribute :delivered, default: []

      def deliver
        delivered << notification
      end
    end
  end
end
