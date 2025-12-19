module Noticed
  module DeliveryMethods
    class Email < DeliveryMethod
      required_options :mailer, :method

      def deliver
        mailer = fetch_constant(:mailer)
        email = evaluate_option(:method)
        args = evaluate_option(:args) || []
        kwargs = evaluate_option(:kwargs) || {}
        mail = mailer.with(params).public_send(email, *args, **kwargs)

        (!!evaluate_option(:enqueue)) ? mail.deliver_later : mail.deliver_now
      end

      def params
        (evaluate_option(:params) || notification&.params || {}).merge(
          notification: notification,
          record: notification&.record,
          recipient: notification&.recipient
        )
      end
    end
  end
end

ActiveSupport.run_load_hooks :noticed_delivery_methods_email, Noticed::DeliveryMethods::Email
