module Noticed
  module DeliveryMethods
    class Email < Base
      option :mailer

      def deliver
        if options[:enqueue]
          composed_mailer.deliver_later
        else
          composed_mailer.deliver_now
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
          notification.send(option)
        else
          option
        end
      end

      # Method should be a symbol
      #
      # If notification responds to symbol, call that method and use return value
      # If notification does not respond to symbol, use the symbol for the mailer method
      # Otherwise, use the underscored notification class name as the mailer method
      def mailer_method
        method_name = options[:method]&.to_sym
        if method_name.present?
          notification.respond_to?(method_name) ? notification.send(method_name) : method_name
        else
          notification.class.name.underscore
        end
      end

      def params
        params = if (method = options[:format])
          notification.send(method)
        else
          notification.params
        end
        params.merge(recipient: recipient, record: record)
      end

      def args
        return unless (option = options[:arguments])

        notification.send(option)
      end

      def composed_mailer
        if options[:arguments]
          mailer.with(params).public_send(mailer_method.to_sym, args)
        else
          mailer.with(params).public_send(mailer_method.to_sym)
        end
      end
    end
  end
end
