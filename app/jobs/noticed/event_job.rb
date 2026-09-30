module Noticed
  class EventJob < Noticed.parent_class.constantize
    def perform(event)
      # Enqueue bulk deliveries
      event.bulk_delivery_methods.each_value do |deliver_by|
        deliver_by.perform_later(event) if deliver_by.perform?(event)
      end

      # Enqueue individual deliveries in batches so large recipient lists don't load into memory all at once
      event.notifications.find_in_batches do |notifications|
        ActiveJob.perform_all_later notifications.flat_map { |notification| delivery_jobs_for(event, notification) }
      end
    end

    private

    def delivery_jobs_for(event, notification)
      event.delivery_methods.values.filter_map do |deliver_by|
        deliver_by.job(notification) if deliver_by.perform?(notification)
      end
    end
  end
end
