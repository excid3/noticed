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
        constant.set(computed_options(options, event_or_notification)).perform_later(name, event_or_notification)
      end

      def ephemeral_perform_later(notifier, recipient, params, options = {})
        constant.set(computed_options(options, recipient))
          .perform_later(name, "#{notifier}::Notification", recipient: recipient, params: params)
      end

      def evaluate_option(name, context)
        option = config[name]

        if option.respond_to?(:call)
          context.instance_exec(&option)
        elsif option.is_a?(Symbol) && context.respond_to?(option, true)
          context.send(option)
        else
          option
        end
      end

      def perform?(notification)
        return true unless config.key?(:before_enqueue)

        perform = false
        catch(:abort) {
          evaluate_option(:before_enqueue, notification)
          perform = true
        }
        perform
      end

      private

      def computed_options(options, recipient)
        options[:wait] ||= evaluate_option(:wait, recipient) if config.has_key?(:wait)
        options[:wait_until] ||= evaluate_option(:wait_until, recipient) if config.has_key?(:wait_until)
        options[:queue] ||= evaluate_option(:queue, recipient) if config.has_key?(:queue)
        options[:priority] ||= evaluate_option(:priority, recipient) if config.has_key?(:priority)
        options
      end
    end
  end
end
