module Noticed
  class Base < Noticed.parent_class.constantize
    class_attribute :delivery_methods, instance_writer: false, default: []
    class_attribute :param_names, instance_writer: false, default: []

    attr_accessor :record

    class << self
      def deliver_by(name, options = {})
        delivery_methods.push(
          name: name,
          options: options
        )
      end

      # Copy delivery methods from parent
      def inherited(base) #:nodoc:
        base.delivery_methods = delivery_methods.dup
        base.param_names = param_names.dup
        super
      end

      def with(params)
        new.with(params)
      end

      def param(name)
        param_names.push(name)
      end
    end

    def with(params)
      @params = params
      self
    end

    def deliver(recipient)
      validate!
      run_delivery(recipient)
    end

    def deliver_later(recipient)
      validate!
      run_delivery(recipient, enqueue: true)
    end

    # ActiveJob interface
    # * recipient - User who should receive the notification
    # * method - A class for the delivery method (email, slack, sms, etc)
    # * record - Database record for the notification (if used)
    # * params - Details required to render the notification
    def perform(recipient, method, record, params)
      # Assign params and record when running jobs
      @params = params
      @record = record
      options = method[:options]

      klass = if method[:name].is_a? Class
        method[:name]
      elsif options[:class]
        options[:class].constantize
      else
        "Noticed::DeliveryMethods::#{method[:name].to_s.classify}".constantize
      end

      klass.new(recipient, self, options).deliver
    end

    def params
      @params || {}
    end

    private

    def run_delivery(recipient, enqueue: false)
      methods = self.class.delivery_methods.dup

      # Run database delivery inline first if it exists so other methods have access to the record
      if (index = methods.find_index { |m| m[:name] == :database })
        method = methods.delete_at(index)
        perform(recipient, method, record, params || {})
      end

      # Run the remaining delivery methods as jobs
      methods.each do |method|
        next if (method_name = method.dig(:options, :if)) && !send(method_name)
        next if (method_name = method.dig(:options, :unless)) && send(method_name)

        if enqueue
          self.class.perform_later(recipient, method, record, params)
        else
          self.class.perform_now(recipient, method, record, params)
        end
      end
    end

    def validate!
      self.class.param_names.each do |param_name|
        if params[param_name].nil?
          raise ValidationError, "#{param_name} is missing."
        end
      end
    end
  end
end
