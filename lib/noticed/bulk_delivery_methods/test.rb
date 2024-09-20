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
