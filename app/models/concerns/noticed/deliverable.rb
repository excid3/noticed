module Noticed
  module Deliverable
    extend ActiveSupport::Concern

    included do
      class_attribute :bulk_delivery_methods, instance_writer: false, default: {}
      class_attribute :delivery_methods, instance_writer: false, default: {}
      class_attribute :required_param_names, instance_writer: false, default: []
      class_attribute :_recipients, instance_writer: false
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

      def recipients(option = nil, &block)
        self._recipients = block || option
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
        if self < Ephemeral
          new(params: params)
        else
          record = params.delete(:record)
          new(params: params, record: record)
        end
      end

      def deliver(recipients = nil, **options)
        new.deliver(recipients, **options)
      end
      alias_method :deliver_later, :deliver
    end

    # Deliver notifications to recipients
    #
    # Examples:
    #   CommentNotifier.deliver(User.all)
    #   CommentNotifier.deliver(User.all, priority: 10)
    #   CommentNotifier.deliver(User.all, queue: :low_priority)
    #   CommentNotifier.deliver(User.all, wait: 5.minutes)
    #   CommentNotifier.deliver(User.all, wait_until: 1.hour.from_now)
    #
    # Job enqueuing behavior:
    #   Jobs are enqueued using after_commit to prevent race conditions and ensure
    #   notifications are persisted before jobs execute. If a transaction is rolled back,
    #   jobs will not be enqueued.
    #
    # Transaction safety:
    #   The deliver method creates its own transaction to save the event and notifications.
    #   When called inside an existing transaction, this creates a nested transaction.
    #   The after_commit callback waits for the outermost transaction to commit, ensuring:
    #
    #     - Jobs are only enqueued if ALL transactions commit successfully
    #     - If your transaction rolls back, the job will NOT be enqueued
    #     - Event and notifications are also rolled back with your transaction
    #     - Safe to call deliver inside your transactions
    #
    #   Example - deliver respects your transaction:
    #     ActiveRecord::Base.transaction do
    #       user = User.create!(name: "Bob")
    #       action = Action.create!(user: user)
    #
    #       ExampleNotifier.deliver(user) # Creates nested transaction internally
    #
    #       raise "Something went wrong!" # Rolls back user, action, event, and notifications
    #       # Job is NOT enqueued because transaction rolled back
    #     end
    #
    def deliver(recipients = nil, enqueue_job: true, **options)
      recipients ||= evaluate_recipients

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

        # Enqueue delivery job after transaction commits to avoid race condition
        # Rails 7.2+ can automatically defer job enqueuing if configured, otherwise we manually defer
        if enqueue_job
          if will_defer_job_enqueuing?
            EventJob.set(options).perform_later(self)
          else
            ActiveRecord::Base.current_transaction.after_commit do
              EventJob.set(options).perform_later(self)
            end
          end
        end
      end

      self
    end
    alias_method :deliver_later, :deliver

    def evaluate_recipients
      return unless _recipients

      if _recipients.respond_to?(:call, true)
        instance_exec(&_recipients)
      elsif _recipients.is_a?(Symbol) && respond_to?(_recipients, true)
        send(_recipients)
      end
    end

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

    private

    # Check if Rails will automatically defer job enqueuing until after transaction commit
    # Returns true for Rails 7.2+ when enqueue_after_transaction_commit is properly configured
    #
    # Rails 7.2+ can automatically defer job enqueuing via the enqueue_after_transaction_commit setting.
    # This method checks three possible values that indicate automatic deferral is enabled:
    #   - :always - Always defer job enqueuing (recommended for production)
    #   - :default - Use Rails default behavior (defers in transactions)
    #   - true - Legacy boolean value for backward compatibility
    def will_defer_job_enqueuing?
      EventJob.respond_to?(:enqueue_after_transaction_commit) &&
        (EventJob.enqueue_after_transaction_commit.in?([:always, :default]) ||
         EventJob.enqueue_after_transaction_commit == true)
    end
  end
end
