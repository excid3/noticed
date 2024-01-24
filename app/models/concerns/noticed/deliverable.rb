module Noticed
  module Deliverable
    extend ActiveSupport::Concern

    included do
      class_attribute :bulk_delivery_methods, instance_writer: false, default: {}
      class_attribute :delivery_methods, instance_writer: false, default: {}
      class_attribute :required_param_names, instance_writer: false, default: []

      attribute :params, default: {}

      if Rails.gem_version >= Gem::Version.new("7.1.0.alpha")
        serialize :params, coder: Coder
      else
        serialize :params, Coder
      end
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

      def deliver(recipients = nil, options = {})
        new.deliver(recipients, options)
      end
    end

    # CommentNotifier.deliver(User.all)
    # CommentNotifier.deliver(User.all, priority: 10)
    # CommentNotifier.deliver(User.all, queue: :low_priority)
    # CommentNotifier.deliver(User.all, wait: 5.minutes)
    # CommentNotifier.deliver(User.all, wait_until: 1.hour.from_now)
    def deliver(recipients = nil, options = {})
      validate!

      transaction do
        save!

        recipients_attributes = Array.wrap(recipients).map do |recipient|
          recipient_attributes_for(recipient)
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
      EventJob.set(options).perform_later(self)

      self
    end

    def recipient_attributes_for(recipient)
      {
        type: "#{self.class.name}::Notification",
        recipient_type: recipient.class.name,
        recipient_id: recipient.id
      }
    end

    def validate!
      validate_params!
      validate_delivery_methods!
    end

    def validate_params!
      required_param_names.each do |param_name|
        raise ValidationError, "Param `#{param_name}` is required for #{self.class.name}." unless params.has_key?(param_name)
      end
    end

    def validate_delivery_methods!
      bulk_delivery_methods.values.each(&:validate!)
      delivery_methods.values.each(&:validate!)
    end
  end
end
