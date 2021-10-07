module Noticed
  module DeliveryMethods
    class Database < Base
      attr_reader :recipients
      # Must return the database record
      def deliver
        # build array of notification attributes
        notifications = build_notifications
        #save all the notification
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

      # retun the class notifications or the association
      def klass
        association_name.to_s.upcase_first.singularize.constantize
      end

      # with the recipients build an array of notifications
      def build_notifications
        Array.wrap(recipients).uniq.map do |recipient|
          build_notification(recipient)
        end
      end

      # new notification and then return the attributes without id and with timestamps
      def build_notification(recipient)
        recipient.send(association_name).new(attributes).attributes.
          merge({created_at: DateTime.current, updated_at: DateTime.current}).
          except("id")
      end

      # if the notification can bulk, use insert_all if not creates records
      def save_notifications(notifications)
        if bulk?
          ids = klass.insert_all!(notifications).rows
          records = klass.find(ids)
        else
          records = klass.create!(notifications)
        end
        records
      end

      def current_adapter
        if ActiveRecord::Base.respond_to?(:connection_db_config)
          ActiveRecord::Base.connection_db_config.adapter
        else
          ActiveRecord::Base.connection_config[:adapter]
        end
      end

      def bulk?
        Rails::VERSION::MAJOR > 6 && ["postgresql", "postgis"].include?(current_adapter)
      end
    end
  end
end
