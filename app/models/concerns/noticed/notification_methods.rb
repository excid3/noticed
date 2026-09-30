module Noticed
  module NotificationMethods
    extend ActiveSupport::Concern

    class_methods do
      # Generate a Notification class each time a Notifier is defined
      #
      # Lookup must not inherit, otherwise a top-level ::Notification model in the host app would be used instead of Noticed::Notification
      def inherited(notifier)
        super
        notifier.const_set :Notification, Class.new(const_defined?(:Notification, false) ? const_get(:Notification, false) : Noticed::Notification)
      end

      def notification_methods(&block)
        const_get(:Notification, false).class_eval(&block)
      end
    end
  end
end
