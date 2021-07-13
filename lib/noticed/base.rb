module Noticed
  class Base
    include Translation
    include Rails.application.routes.url_helpers

    extend ActiveModel::Callbacks
    define_model_callbacks :deliver

    class_attribute :delivery_methods, instance_writer: false, default: []
    class_attribute :param_names, instance_writer: false, default: []

    # Gives notifications access to the record and recipient during delivery
    attr_accessor :record, :recipient, :recipients

    delegate :read?, :unread?, to: :record

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

      recipients = Array.wrap(recipients).uniq

      run_callbacks :deliver do
        run_all_deliveries(recipients, enqueue: false)
      end
    end

    def deliver_later(recipients)
      validate!

      recipients = Array.wrap(recipients).uniq

      run_callbacks :deliver do
        run_all_deliveries(recipients, enqueue: true)
      end
    end

    def params
      @params || {}
    end

    private

    # Runs all delivery methods for a notification
    def run_all_deliveries(recipients, enqueue: true)
      individual_delivery_methods, bulk_delivery_methods = segregate_delivery_methods

      run_individual_deliveries(individual_delivery_methods, recipients, enqueue: enqueue)
      run_bulk_deliveries(bulk_delivery_methods, recipients, enqueue: enqueue)
    end

    def run_individual_deliveries(delivery_methods, recipients, enqueue: true)
      if (index = delivery_methods.find_index { |m| m[:name] == :database })
        database_delivery_method = delivery_methods.delete_at(index)
      end

      recipients.each do |recipient|
        # Run database delivery inline first if it exists so other methods have access to the record
        if database_delivery_method
          notification_record = run_individual_delivery(database_delivery_method, recipient: recipient, enqueue: false, record: nil)
        end

        delivery_methods.each do |delivery_method|
          run_individual_delivery(delivery_method, recipient: recipient, enqueue: enqueue, record: notification_record)
        end
      end
    end

    def run_bulk_deliveries(delivery_methods, recipients, enqueue: true)
      delivery_methods.each do |delivery_method|
        group_size = delivery_method.dig(:options, :bulk, :group_size)

        recipients.each_slice(group_size) do |recipients_batch|
          run_bulk_delivery(delivery_method, recipients: recipients_batch, enqueue: enqueue)
        end
      end
    end

    # Actually runs a bulk delivery
    def run_bulk_delivery(delivery_method, recipients:, enqueue:)
      args = {
        notification_class: self.class.name,
        options: delivery_method[:options],
        params: params,
        recipients: recipients
      }

      run_delivery(delivery_method: delivery_method, args: args, enqueue: enqueue)
    end

    # Actually runs an individual delivery
    def run_individual_delivery(delivery_method, recipient:, enqueue:, record:)
      args = {
        notification_class: self.class.name,
        options: delivery_method[:options],
        params: params,
        recipient: recipient,
        record: record
      }

      run_delivery(delivery_method: delivery_method, args: args, enqueue: enqueue)
    end

    def run_delivery(delivery_method:, args:, enqueue:)
      run_callbacks delivery_method[:name] do
        method = delivery_method_for(delivery_method[:name], delivery_method[:options])

        # If the queue is `nil`, ActiveJob will use a default queue name.
        queue = delivery_method.dig(:options, :queue)

        # Always perfrom later if a delay is present
        if (delay = delivery_method.dig(:options, :delay))
          method.set(wait: delay, queue: queue).perform_later(args)
        elsif enqueue
          method.set(queue: queue).perform_later(args)
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

    def segregate_delivery_methods
      all_delivery_methods = self.class.delivery_methods.dup

      bulk_delivery_methods = all_delivery_methods.select do |delivery_method|
        delivery_method.dig(:options, :bulk)
      end

      individual_delivery_methods = all_delivery_methods - bulk_delivery_methods

      [individual_delivery_methods, bulk_delivery_methods]
    end
  end
end
