module Noticed
  module Deliverable
    extend ActiveSupport::Concern

    included do
      class_attribute :bulk_delivery_methods, instance_writer: false, default: {}
      class_attribute :delivery_methods, instance_writer: false, default: {}
      class_attribute :required_param_names, instance_writer: false, default: []

      attribute :params, default: {}

      # Ephemeral notifiers cannot serialize params since they aren't ActiveRecord backed
      if respond_to? :serialize
        if Rails.gem_version >= Gem::Version.new("7.1.0.alpha")
          serialize :params, coder: Coder
        else
          serialize :params, Coder
        end
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

        if name == :database
          Noticed.deprecator.warn <<-WARNING.squish
            The :database delivery method has been deprecated and does nothing. Notifiers automatically save to the database now.
          WARNING
          return
        end

        config = ActiveSupport::OrderedOptions.new.merge(options)
        yield config if block_given?
        delivery_methods[name] = DeliverBy.new(name, config)
      end

      def required_params(*names)
        required_param_names.concat names
      end
      alias_method :required_param, :required_params

      def params(*names)
        Noticed.deprecator.warn <<-WARNING.squish
          `params` is deprecated and has been renamed to `required_params`
        WARNING
        required_params(*names)
      end

      def param(*names)
        Noticed.deprecator.warn <<-WARNING.squish
          `param :name` is deprecated and has been renamed to `required_param :name`
        WARNING
        required_params(*names)
      end

      def with(params)
        record = params.delete(:record)
        new(params: params, record: record)
      end

      def deliver(recipients = nil, **options)
        new.deliver(recipients, **options)
      end
      alias_method :deliver_later, :deliver
    end

    # CommentNotifier.deliver(User.all)
    # CommentNotifier.deliver(User.all, priority: 10)
    # CommentNotifier.deliver(User.all, queue: :low_priority)
    # CommentNotifier.deliver(User.all, wait: 5.minutes)
    # CommentNotifier.deliver(User.all, wait_until: 1.hour.from_now)
    def deliver(recipients = nil, enqueue_job: true, **options)
      validate!

      transaction do
        recipients_attributes = Array.wrap(recipients).map do |recipient|
          recipient_attributes_for(recipient)
        end

        self.notifications_count = recipients_attributes.size
        save!

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
      EventJob.set(options).perform_later(self) if enqueue_job

      self
    end
    alias_method :deliver_later, :deliver

    def recipient_attributes_for(recipient)
      {
        type: "#{self.class.name}::Notification",
        recipient_type: recipient.class.base_class.name,
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

    # If a GlobalID record in params is no longer found, the params will default with a noticed_error key
    def deserialize_error?
      !!params[:noticed_error]
    end
  end
end
