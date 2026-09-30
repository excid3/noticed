module Noticed
  class EventJob < Noticed.parent_class.constantize
    def perform(event)
      # Enqueue bulk deliveries
      event.bulk_delivery_methods.each_value do |deliver_by|
        deliver_by.perform_later(event) if deliver_by.perform?(event)
      end

      # Enqueue individual deliveries in batches so large recipient lists don't load into memory all at once
      event.notifications.find_in_batches do |notifications|
        jobs = notifications.flat_map do |notification|
          event.delivery_methods.values.filter_map do |deliver_by|
            deliver_by.job(notification) if deliver_by.perform?(notification)
          end
        end

        enqueue_all jobs
      end
    end

    private

    # perform_all_later was added in Rails 7.1
    def enqueue_all(jobs)
      if ActiveJob.respond_to?(:perform_all_later)
        ActiveJob.perform_all_later(jobs)
      else
        jobs.each(&:enqueue)
      end
    end
  end
end
