module Noticed
  module DeliveryMethods
    class Email < Base
      option :mailer

      def deliver
        mailer.with(format).send(method.to_sym).deliver_now
      end

      private

      def mailer
        options.fetch(:mailer).constantize
      end

      def method
        options[:method] || notifier.class.name.underscore
      end

      def format
        params = if (method = options[:format])
          notifier.send(method)
        else
          notifier.params
        end
        params.merge(recipient: recipient, record: record)
      end
    end
  end
end
