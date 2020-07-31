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
      self.class.delivery_methods.each do |method|
        self.class.perform_now(recipient, method, params || {})
      end
    end

    def deliver_later(recipient)
      self.class.delivery_methods.each do |method|
        self.class.perform_later(recipient, method, params || {})
      end
    end

    def perform(recipient, method, params = {})
      @params = params

      options = method[:options]

      klass = if options[:class]
                options[:class].constantize
              else
                "Noticed::DeliveryMethods::#{method[:name].to_s.classify}".constantize
              end

      klass.new(recipient, self, options).deliver
    end
  end
end
