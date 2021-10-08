module Noticed
  module DeliveryMethods
    class Email < Base
      option :mailer

      def deliver
        mailer.with(format).send(method.to_sym).deliver_now
      end

      private

      def mailer
        option = options.fetch(:mailer)
        case option
        when String
          option.constantize
        when Symbol
          send(option)
        else
          option
        end
      end

      def method
        options[:method] || notification.class.name.underscore
      end

      def format
        params = if (method = options[:format])
          notification.send(method)
        else
          notification.params
        end
        params.merge(recipient: recipient, record: record)
      end
    end
  end
end
