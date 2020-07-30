module Noticed
  class Base
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
      new(data)
    end

    def self.klass_for_name(name)
      return name if name.is_a? Class

      name = name.to_s if name.is_a? Symbol
      name = "Noticed::DeliveryMethods::#{name.classify}"

      name.include?("::") ? name.constantize : const_get(name)
    end

    def initialize(params = {})
      @params = params.with_indifferent_access
    end

    def deliver(recipient)
      self.class.delivery_methods.each do |method|
        name, klass, options = method[:name], method[:class], method[:options]

        if deliver?(name)
          klass.new(recipient, self, options).with(params).deliver
        end
      end
    end

    def deliver?(method)
      # Allow user preferences to disable types of notifications
      true
    end
  end
end
