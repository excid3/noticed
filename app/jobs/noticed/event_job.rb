module Noticed
  class EventJob < ApplicationJob
    queue_as :default

    def perform(event)
      # Enqueue bulk deliveries
      event.bulk_delivery_methods.each_value do |deliver_by|
        deliver_by.perform_later(event)
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
