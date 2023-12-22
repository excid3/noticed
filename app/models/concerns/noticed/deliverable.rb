module Noticed
  module Deliverable
    extend ActiveSupport::Concern

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
          raise ValidationError, "option `#{option}` must be set for `deliver_by :#{name}`" unless config.has_key?(option)
        end
      end

      def perform_later(event)
        constant.perform_later(name, event)
      end
    end

    included do
      class_attribute :bulk_delivery_methods, instance_writer: false, default: {}
      class_attribute :delivery_methods, instance_writer: false, default: {}
      class_attribute :required_param_names, instance_writer: false, default: []
    end

    class_methods do
      def inherited(base)
        base.bulk_delivery_methods = bulk_delivery_methods.dup
        base.delivery_methods = delivery_methods.dup
        base.required_param_names = required_param_names.dup
        super
      end

      def bulk_deliver_by(name, options = {})
        raise NameError, "#{name} has already been used for this Notifier." if bulk_delivery_methods.has_key?(name)

        config = ActiveSupport::OrderedOptions.new.merge(options)
        yield config if block_given?
        bulk_delivery_methods[name] = DeliverBy.new(name, config, bulk: true)
      end

      def deliver_by(name, options = {})
        raise NameError, "#{name} has already been used for this Notifier." if delivery_methods.has_key?(name)

        config = ActiveSupport::OrderedOptions.new.merge(options)
        yield config if block_given?
        delivery_methods[name] = DeliverBy.new(name, config)
      end

      def required_params(*names)
        required_param_names.concat names
      end
      alias_method :required_param, :required_params

      def with(params)
        record = params.delete(:record)
        new(params: params, record: record)
      end

      def deliver(recipients = nil)
        new.deliver(recipients)
      end
    end

    def deliver(recipients = nil)
      validate!

      transaction do
        save!

        recipients_attributes = Array.wrap(recipients).map do |recipient|
          {
            recipient_type: recipient.class.name,
            recipient_id: recipient.id
          }
        end

        if Rails.gem_version >= Gem::Version.new("7.0.0.alpha1")
          notifications.insert_all!(recipients_attributes, record_timestamps: true) if recipients_attributes.any?
        else
          time = Time.current
          recipients_attributes.each do |attributes|
            attributes[:created_at] = time
            attributes[:updated_at] = time
          end
          notifications.insert_all!(recipients_attributes) if recipients_attributes.any?
        end
      end

      # Enqueue delivery job
      EventJob.perform_later(self)

      self
    end

    def validate!
      validate_params!
      validate_delivery_methods!
    end

    def validate_params!
      required_param_names.each do |param_name|
        raise ValidationError, "Param `#{param_name}` is required for #{self.class.name}." unless params.has_key?(param_name.to_s)
      end
    end

    def validate_delivery_methods!
      bulk_delivery_methods.values.each(&:validate!)
      delivery_methods.values.each(&:validate!)
    end
  end
end
