module Noticed
  class BulkDeliveryMethod < ApplicationJob
    include ApiClient
    include RequiredOptions

    class_attribute :logger, default: Rails.logger

    attr_reader :config, :event

    def perform(delivery_method_name, event)
      @event = event
      @config = event.bulk_delivery_methods.fetch(delivery_method_name).config

      return false if config.has_key?(:if) && !evaluate_option(:if)
      return false if config.has_key?(:unless) && evaluate_option(:unless)

      deliver
    end

    def deliver
      raise NotImplementedError, "Bulk delivery methods must implement the `deliver` method"
    end

    def fetch_constant(name)
      option = config[name]
      option.is_a?(String) ? option.constantize : option
    end

    def evaluate_option(name)
      option = config[name]

      # Evaluate Proc within the context of the notifier
      if option&.respond_to?(:call)
        event.instance_exec(&option)

      # Call method if symbol and matching method
      elsif option.is_a?(Symbol) && event.respond_to?(option)
        event.send(option)

      # Return the value
      else
        option
      end
    end
  end
end
