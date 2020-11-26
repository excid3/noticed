module Noticed
  class Base
    include Translation
    include Rails.application.routes.url_helpers

    extend ActiveModel::Callbacks
    define_model_callbacks :deliver

    class_attribute :delivery_methods, instance_writer: false, default: []
    class_attribute :param_names, instance_writer: false, default: []
    class_attribute :set_options, default: {}

    # Gives notifications access to the record and recipient when formatting for delivery
    attr_accessor :record, :recipient

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

      def params(*names)
        param_names.concat Array.wrap(names)
      end
      alias_method :param, :params
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

    def set(options)
      self.set_options = options
      self
    end

    private

    # Runs all delivery methods for a notification
    def run_delivery(recipient, enqueue: true)
      delivery_methods = self.class.delivery_methods.dup

      # Set recipient to instance var so it is available to Notification class
      @recipient = recipient

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
      args = {
        notification_class: self.class.name,
        options: delivery_method[:options],
        params: params,
        recipient: recipient,
        record: record
      }

      run_callbacks delivery_method[:name] do
        method = delivery_method_for(delivery_method[:name], delivery_method[:options])

        # Always perfrom later if a delay is present
        if (delay = delivery_method.dig(:options, :delay))
          # Join delay and set_options :wait
          wait = delay.to_i + set_options.dig(:wait).to_i
          set_options[:wait] = wait
          method.set(set_options).perform_later(args)
        elsif enqueue && set_options.present?
          method.set(set_options).perform_later(args)
        elsif enqueue
          method.perform_later(args)
        else
          method.perform_now(args)
        end
      end
    end

    def delivery_method_for(name, options)
      if options[:class]
        options[:class].constantize
      else
        "Noticed::DeliveryMethods::#{name.to_s.camelize}".constantize
      end
    end

    def validate!
      validate_params_present!
      validate_options_of_delivery_methods!
    end

    # Validates that all params are present
    def validate_params_present!
      self.class.param_names.each do |param_name|
        if params[param_name].nil?
          raise ValidationError, "#{param_name} is missing."
        end
      end
    end

    def validate_options_of_delivery_methods!
      delivery_methods.each do |delivery_method|
        method = delivery_method_for(delivery_method[:name], delivery_method[:options])
        method.validate!(delivery_method[:options])
      end
    end
  end
end
