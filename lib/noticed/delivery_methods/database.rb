module Noticed
  module DeliveryMethods
    class Database < Base
      # Must return the database record
      def deliver
        association_name = options.fetch(:association, :notifications)
        recipient.send(association_name).create!(attributes)
      end

      def self.validate!(options)
        super

        # Must be executed right away so the other deliveries can access the db record
        raise ArgumentError, "database delivery cannot be delayed" if options.key?(:delay)
      end

      private

      def attributes
        record = notification.params.delete(:record)
        {
          params: notification.params,
          record: record,
          type: notification.class.name
        }.merge(custom_attributes)
      end

      def custom_attributes
        method = (options[:attributes] || options[:format])
        return {} unless method.present?

        method.respond_to?(:call) ? notification.instance_eval(&method) : notification.send(method)
      end
    end
  end
end
