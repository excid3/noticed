module Noticed
  module DeliveryMethods
    class Test < Base
      class_attribute :delivered, default: []
      class_attribute :callbacks, default: []

      after_deliver do
        self.class.callbacks << :after
      end

      def self.clear!
        delivered.clear
        callbacks.clear
      end

      def deliver
        self.class.delivered << notification
      end
    end
  end
end
