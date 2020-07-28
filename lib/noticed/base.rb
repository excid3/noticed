module Noticed
  class Base
    class_attribute :delivery_methods, instance_writer: false, default: []

    attr_accessor :data

    def self.deliver_with(name, options={})
      if options.delete(:prepend)
        delivery_methods.unshift(name)
      else
        delivery_methods.push(name)
      end
    end

    # Copy delivery methods from parent
    def self.inherited(base) #:nodoc:
      base.delivery_methods = delivery_methods.dup
      super
    end

    def initialize(data={})
      @data = data.with_indifferent_access
    end

    def notify(recipient)
      self.class.delivery_methods.each do |method|
        send(:"deliver_with_#{method}", recipient)
      end
    end
  end
end
