module Noticed
  module DeliveryMethods
    class Email < Base
      def deliver
        mailer.with(notification.params).send(method.to_sym).deliver_later
      end

      def mailer
        options[:mailer].constantize
      end

      def method
        options[:method] || notification.class.name.underscore
      end
    end
  end
end
