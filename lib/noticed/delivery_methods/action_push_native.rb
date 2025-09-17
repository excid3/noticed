module Noticed
  module DeliveryMethods
    class ActionPushNative < DeliveryMethod
      required_options :devices, :format

      def deliver
        notification = notification_class
          .with_apple(evaluate_option(:apple))
          .with_google(evaluate_option(:google))
          .with_data(evaluate_option(:data))
          .new(evaluate_option(:format))

        notification.deliver_later_to(evaluate_option(:devices))
      end

      def notification_class
        fetch_constant(:class) || ApplicationPushNotification
      end
    end
  end
end

ActiveSupport.run_load_hooks :noticed_delivery_methods_action_push_native, Noticed::DeliveryMethods::ActionPushNative
