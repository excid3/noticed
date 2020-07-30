module Noticed
  module DeliveryMethods
    class Test < Base
      class_attribute :delivered, default: []

      def self.clear!
        delivered.clear
      end

      def deliver
        self.class.delivered << notification
      end
    end
  end
end
