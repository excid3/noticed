module Noticed
  module DeliveryMethods
    class ActionPushNative < DeliveryMethod
      required_options :devices, :format

      def deliver
        notification = evaluate_option(:silent) ? notification_class : notification_class.silent

        notification
          .with_apple(evaluate_option(:apple_data))
          .with_google(evaluate_option(:google_data))
          .with_data(evaluate_option(:data))
          .new(**evaluate_option(:format))

        notification.deliver_later_to(evaluate_option(:devices))
      end

      def notification_class
        fetch_constant(:class) || ApplicationPushNotification
      end
    end
  end
end

ActiveSupport.run_load_hooks :noticed_delivery_methods_action_push_native, Noticed::DeliveryMethods::ActionPushNative
