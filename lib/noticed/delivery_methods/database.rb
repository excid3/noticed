module Noticed
  module DeliveryMethods
    class Database < Base
      attr_reader :recipients
      # Must return the database record
      def deliver
        to_store = Array.wrap(recipients).uniq.map do |recipient|
          recipient.send(association_name).new(attributes).attributes
        end
        relation.create!(to_store)
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

      def relation
        association_name.to_s.upcase_first.singularize.constantize
      end
    end
  end
end
