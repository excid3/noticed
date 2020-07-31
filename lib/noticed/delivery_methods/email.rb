module Noticed
  module DeliveryMethods
    class Email < Base
      def deliver
        name = notification.class.name.underscore
        # TODO: include notificiation in arguments
        mailer.with(notification.params).send(name.to_sym).deliver_later
      end

      def mailer
        options[:mailer].constantize
      end
    end
  end
end
