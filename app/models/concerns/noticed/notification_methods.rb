module Noticed
  module NotificationMethods
    extend ActiveSupport::Concern

    class_methods do
      # Generate a Notification class each time a Notifier is defined
      def inherited(notifier)
        super
        notifier.const_set :Notification, Class.new(const_defined?(:Notification) ? const_get(:Notification) : Noticed::Notification)
      end

      def notification_methods(&block)
        const_get(:Notification).class_eval(&block)
      end
    end
  end
end
