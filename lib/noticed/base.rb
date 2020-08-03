module Noticed
  class Base
    include Translation
    include Rails.application.routes.url_helpers

    extend ActiveModel::Callbacks
    define_model_callbacks :deliver

    class_attribute :delivery_methods, instance_writer: false, default: []
    class_attribute :param_names, instance_writer: false, default: []

    attr_accessor :record

    class << self
      def deliver_by(name, options = {})
        delivery_methods.push(name: name, options: options)
        define_model_callbacks(name)
      end

      # Copy delivery methods from parent
      def inherited(base) #:nodoc:
        base.delivery_methods = delivery_methods.dup
        base.param_names = param_names.dup
        super
      end

      def with(params)
        new(params)
      end

      def param(name)
        param_names.push(name)
      end
    end

    def initialize(params = {})
      @params = params
    end

    def deliver(recipients)
      validate!

      run_callbacks :deliver do
        Array.wrap(recipients).uniq.each do |recipient|
          run_delivery(recipient, enqueue: false)
        end
      end
    end

    def deliver_later(recipients)
      validate!

      run_callbacks :deliver do
        Array.wrap(recipients).uniq.each do |recipient|
          run_delivery(recipient, enqueue: true)
        end
      end
    end

    def params
      @params || {}
    end

    private

    # Runs all delivery methods for a notification
    def run_delivery(recipient, enqueue: true)
      delivery_methods = self.class.delivery_methods.dup

      # Run database delivery inline first if it exists so other methods have access to the record
      if (index = delivery_methods.find_index { |m| m[:name] == :database })
        delivery_method = delivery_methods.delete_at(index)
        @record = run_delivery_method(delivery_method, recipient: recipient, enqueue: false)
      end

      delivery_methods.each do |delivery_method|
        run_delivery_method(delivery_method, recipient: recipient, enqueue: enqueue)
      end
    end

    # Actually runs an individual delivery
    def run_delivery_method(delivery_method, recipient:, enqueue:)
      return if (delivery_method_name = delivery_method.dig(:options, :if)) && !send(delivery_method_name)
      return if (delivery_method_name = delivery_method.dig(:options, :unless)) && send(delivery_method_name)

      args = {
        notification_class: self.class.name,
        options: delivery_method[:options],
        params: params,
        recipient: recipient,
        record: record
      }

      run_callbacks delivery_method[:name] do
        klass = get_class(delivery_method[:name], delivery_method[:options])
        enqueue ? klass.perform_later(args) : klass.perform_now(args)
      end
    end

    # Retrieves the correct class for a delivery method
    def get_class(name, options)
      if options[:class]
        options[:class].constantize
      else
        "Noticed::DeliveryMethods::#{name.to_s.classify}".constantize
      end
    end

    # Validates that all params are present
    def validate!
      self.class.param_names.each do |param_name|
        if params[param_name].nil?
          raise ValidationError, "#{param_name} is missing."
        end
      end
    end
  end
end
