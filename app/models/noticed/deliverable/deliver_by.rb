module Noticed
  module Deliverable
    class DeliverBy
      attr_reader :name, :config, :bulk

      def initialize(name, config, bulk: false)
        @name, @config, @bulk, = name, config, bulk
      end

      def constant
        namespace = bulk ? "Noticed::BulkDeliveryMethods" : "Noticed::DeliveryMethods"
        config.fetch(:class, [namespace, name.to_s.camelize].join("::")).constantize
      end

      def validate!
        constant.required_option_names.each do |option|
          raise ValidationError, "option `#{option}` must be set for `deliver_by :#{name}`" unless config[option].present?
        end
      end

      def perform_later(event_or_notification, options = {})
        options[:wait] = evaluate_option(:wait, event_or_notification) if config.has_key?(:wait)
        options[:wait_until] = evaluate_option(:wait_until, event_or_notification) if config.has_key?(:wait_until)
        options[:queue] = evaluate_option(:queue, event_or_notification) if config.has_key?(:queue)
        options[:priority] = evaluate_option(:priority, event_or_notification) if config.has_key?(:priority)

        constant.set(options).perform_later(name, event_or_notification)
      end

      def evaluate_option(name, context)
        option = config[name]

        if option&.respond_to?(:call)
          context.instance_exec(&option)
        elsif option.is_a?(Symbol) && context.respond_to?(option)
          context.send(option)
        else
          option
        end
      end
    end
  end
end
