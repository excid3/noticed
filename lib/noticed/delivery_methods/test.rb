module Noticed
  module DeliveryMethods
    class Test < Base
      class_attribute :individual_deliveries, default: []
      class_attribute :bulk_deliveries, default: []
      class_attribute :callbacks, default: []

      after_deliver do
        self.class.callbacks << :after
      end

      def self.clear!
        individual_deliveries.clear
        bulk_deliveries.clear
        callbacks.clear
      end

      def deliver
        self.class.individual_deliveries << notification
      end

      def bulk_deliver
        self.class.bulk_deliveries << notification
      end
    end
  end
end
