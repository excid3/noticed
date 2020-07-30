module Noticed
  module DeliveryMethods
    class Base
      attr_reader :notification, :options, :params, :recipient

      def initialize(recipient, notification, options = {})
        @recipient = recipient
        @notification = notification
        @options = options
      end

      def with(params)
        @params = params
        self
      end

      def deliver
        raise NotImplementedError, "Delivery methods must implement a deliver method"
      end
    end
  end
end
