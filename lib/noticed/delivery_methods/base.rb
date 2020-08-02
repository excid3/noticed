module Noticed
  module DeliveryMethods
    class Base < Noticed.parent_class.constantize
      attr_reader :notification, :options, :recipient
      delegate :params, to: :notification

      def perform(notification_class:, options:, params:, recipient:, record:)
        @notification = notification_class.constantize.new(params)
        @options = options
        @recipient = recipient

        # Keep track of the database record for rendering
        @notification.record = record

        deliver
      end

      def deliver
        raise NotImplementedError, "Delivery methods must implement a deliver method"
      end
    end
  end
end
