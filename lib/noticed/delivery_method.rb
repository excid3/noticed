module Noticed
  class DeliveryMethod < Noticed.parent_class.constantize
    include ApiClient
    include RequiredOptions

    extend ActiveModel::Callbacks
    define_model_callbacks :deliver

    class_attribute :logger, default: Rails.logger

    attr_reader :config, :event, :notification
    delegate :recipient, to: :notification
    delegate :record, :params, to: :event

    def perform(delivery_method_name, notification, overrides: {})
      @notification = notification
      @event = notification.event

      # Look up config from Notifier and merge overrides
      @config = event.delivery_methods.fetch(delivery_method_name).config.merge(overrides)

      return false if config.has_key?(:if) && !evaluate_option(:if)
      return false if config.has_key?(:unless) && evaluate_option(:unless)

      run_callbacks :deliver do
        deliver
      end
    end

    def deliver
      raise NotImplementedError, "Delivery methods must implement the `deliver` method"
    end

    def fetch_constant(name)
      option = config[name]
      option.is_a?(String) ? option.constantize : option
    end

    def evaluate_option(name)
      option = config[name]

      # Evaluate Proc within the context of the Notification
      if option&.respond_to?(:call)
        notification.instance_exec(&option)

      # Call method if symbol and matching method on Notifier
      elsif option.is_a?(Symbol) && event.respond_to?(option)
        event.send(option, notification)

      # Return the value
      else
        option
      end
    end
  end
end
