module Noticed
  module DeliveryMethods
    class Database < Base
      attr_reader :recipients
      # Must return the database record
      def deliver
        notifications = build_notifications
        save_notifications(notifications)
      end

      def self.validate!(options)
        super

        # Must be executed right away so the other deliveries can access the db record
        raise ArgumentError, "database delivery cannot be delayed" if options.key?(:delay)
      end

      def perform(args)
        @recipients = args[:recipients]

        super
      end

      private

      def association_name
        options[:association] || :notifications
      end

      def attributes
        if (method = options[:format])
          notification.send(method)
        else
          {
            type: notification.class.name,
            params: notification.params
          }
        end
      end

      def klass
        association_name.to_s.upcase_first.singularize.constantize
      end

      def build_notifications
        Array.wrap(recipients).uniq.map do |recipient|
          build_notification(recipient)
        end
      end

      def build_notification(recipient)
        recipient.send(association_name).new(attributes).attributes.
          merge({created_at: DateTime.current, updated_at: DateTime.current}).
          except("id")
      end

      def save_notifications(notifications)
        ids = klass.insert_all!(notifications).rows
        klass.find(ids)
      end
    end
  end
end
