module Noticed
  class DelayNotificationJob < Noticed.parent_class.constantize
    def perform(args)
      notification = args[:notification_class].constantize.with(args[:params])
      notification.recipient = args[:recipient]
      notification.record = args[:record]
      notification.send(:run_delivery_method, args[:delivery_method], recipient: notification.recipient, enqueue: args[:enqueue])
    end
  end
end
