module Noticed
  module DeliveryMethods
    class Email < DeliveryMethod
      required_options :mailer, :method

      def deliver
        mailer = fetch_constant(:mailer)
        email = evaluate_option(:method)
        params = evaluate_option(:params) || notification&.params&.merge(record: notification.record)
        args = evaluate_option(:args)

        mail = mailer.with(params)
        mail = args.present? ? mail.send(email, *args) : mail.send(email)

        (!!evaluate_option(:enqueue)) ? mail.deliver_later : mail.deliver_now
      end
    end
  end
end
