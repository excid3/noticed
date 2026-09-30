module Noticed
  class Ephemeral
    include ActiveModel::Model
    include ActiveModel::Attributes
    include Noticed::Deliverable
    include Noticed::Translation
    include Rails.application.routes.url_helpers

    attribute :params, default: {}

    class Notification
      include ActiveModel::Model
      include ActiveModel::Attributes
      include Noticed::Translation
      include Rails.application.routes.url_helpers

      attribute :recipient
      attribute :event

      delegate :params, :record, to: :event

      def self.new_with_params(recipient, params)
        instance = new(recipient: recipient)
        instance.event = module_parent.new(params: params)
        instance
      end
    end

    # Dynamically define Notification on each Ephemeral Notifier, inheriting from the parent Notifier's Notification
    def self.inherited(notifier)
      super
      notifier.const_set :Notification, Class.new(const_defined?(:Notification, false) ? const_get(:Notification, false) : Noticed::Ephemeral::Notification)
    end

    def self.notification_methods(&block)
      const_get(:Notification, false).class_eval(&block)
    end

    # EphemeralNotifier.with(message: "test").deliver(User.all, wait: 5.minutes)
    def deliver(recipients = nil, **options)
      recipients ||= evaluate_recipients
      recipients = Array.wrap(recipients)

      validate!

      bulk_delivery_methods.each_value do |deliver_by|
        deliver_by.ephemeral_perform_later(self.class.name, recipients, params, options.dup, context: self) if deliver_by.perform?(self)
      end

      recipients.each do |recipient|
        notification = self.class::Notification.new(recipient: recipient, event: self)

        delivery_methods.each_value do |deliver_by|
          deliver_by.ephemeral_perform_later(self.class.name, recipient, params, options.dup, context: notification) if deliver_by.perform?(notification)
        end
      end

      self
    end
    alias_method :deliver_later, :deliver

    def record
      params[:record]
    end
  end
end

ActiveSupport.run_load_hooks :noticed_ephemeral, Noticed::Ephemeral
