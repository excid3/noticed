module Noticed
  module DeliveryMethods
    class Email < Base
      option :mailer

      def deliver
        if options[:enqueue]
          mailer.with(format).send(method.to_sym).deliver_later
        else
          mailer.with(format).send(method.to_sym).deliver_now
        end
      end

      private

      # mailer: "UserMailer"
      # mailer: UserMailer
      # mailer: :my_method - `my_method` should return Class
      def mailer
        option = options.fetch(:mailer)
        case option
        when String
          option.constantize
        when Symbol
          notifier.send(option)
        else
          option
        end
      end

      # Method should be a symbol
      #
      # If notifier responds to symbol, call that method and use return value
      # If notifier does not respond to symbol, use the symbol for the mailer method
      # Otherwise, use the underscored notifier class name as the mailer method
      def method
        method_name = options[:method]&.to_sym
        if method_name.present?
          notifier.respond_to?(method_name) ? notifier.send(method_name) : method_name
        else
          notifier.class.name.underscore
        end
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
