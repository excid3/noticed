module Noticed
  class Base < Noticed.parent_class.constantize
    class_attribute :delivery_methods, instance_writer: false, default: []

    attr_accessor :params, :record

    def self.deliver_by(name, options = {})
      delivery_methods.push(
        name: name,
        options: options
      )
    end

    # Copy delivery methods from parent
    def self.inherited(base) #:nodoc:
      base.delivery_methods = delivery_methods.dup
      super
    end

    def self.with(data = {})
      new.with(data)
    end

    def with(params)
      @params = params.with_indifferent_access
      self
    end

    def deliver(recipient)
      run_delivery(recipient)
    end

    def deliver_later(recipient)
      run_delivery(recipient, enqueue: true)
    end

    # ActiveJob interface
    # * recipient - User who should receive the notification
    # * method - A class for the delivery method (email, slack, sms, etc)
    # * record - Database record for the notification (if used)
    # * params - Details required to render the notification
    def perform(recipient, method, record, params = {})
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
        if enqueue
          self.class.perform_later(recipient, method, record, params || {})
        else
          self.class.perform_now(recipient, method, record, params || {})
        end
      end
    end
  end
end
