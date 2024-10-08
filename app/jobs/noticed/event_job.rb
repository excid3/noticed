module Noticed
  class EventJob < Noticed.parent_class.constantize
    def perform(event)
      # Enqueue bulk deliveries
      event.bulk_delivery_methods.each_value do |deliver_by|
        deliver_by.perform_later(event) if deliver_by.perform?(event)
      end

      # Enqueue individual deliveries
      event.notifications.each do |notification|
        event.delivery_methods.each_value do |deliver_by|
          deliver_by.perform_later(notification) if deliver_by.perform?(notification)
        end
      end
    end
  end
end
