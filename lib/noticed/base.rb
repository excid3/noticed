module Noticed
  class Base < Noticed.parent_class.constantize
    class_attribute :delivery_methods, instance_writer: false, default: []

    attr_accessor :params, :record

    def self.deliver_by(name, options = {})
      delivery_methods.push(
        name: name,
        class: klass_for_name(name),
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

    def self.klass_for_name(name)
      return name if name.is_a? Class

      name = name.to_s if name.is_a? Symbol
      name = "Noticed::DeliveryMethods::#{name.classify}"

      name.include?("::") ? name.constantize : const_get(name)
    end

    def with(params)
      @params = params.with_indifferent_access
      self
    end

    def deliver(recipient)
      self.class.perform_now(recipient, params || {})
    end

    def deliver_later(recipient)
      self.class.perform_later(recipient, params || {})
    end

    def perform(recipient, params = {})
      @params = params

      self.class.delivery_methods.each do |method|
        klass, options = method[:class], method[:options]
        klass.new(recipient, self, options).deliver
      end
    end
  end
end
