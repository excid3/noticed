module Noticed
  module DeliveryMethods
    class Base
      attr_reader :notification, :options, :recipient
      delegate :params, to: :notification

      def initialize(recipient, notification, options = {})
        @recipient = recipient
        @notification = notification
        @options = options
      end

      def deliver
        raise NotImplementedError, "Delivery methods must implement a deliver method"
      end
    end
  end
end
