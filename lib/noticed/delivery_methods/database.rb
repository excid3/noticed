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
        if Rails::VERSION::MAJOR > 6 && ["postgresql", "postgis"].include?(current_adapter)
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
    end
  end
end
