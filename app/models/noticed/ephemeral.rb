module Noticed
  class Ephemeral
    include ActiveModel::Model
    include ActiveModel::Attributes
    include Noticed::Deliverable

    class Notification
      include ActiveModel::Model
      include ActiveModel::Attributes

      attribute :recipient
      attribute :event

      delegate :params, :record, to: :event

      def self.new_with_params(recipient, params)
        instance = new(recipient: recipient)
        instance.event = module_parent.new(params: params)
        instance
      end
    end

    attribute :params, default: {}

    def deliver(recipients)
      recipients = Array.wrap(recipients)
      bulk_delivery_methods.each do |_, deliver_by|
        deliver_by.ephemeral_perform_later(self.class.name, recipients, params)
      end

      recipients.each do |recipient|
        delivery_methods.each do |_, deliver_by|
          deliver_by.ephemeral_perform_later(self.class.name, recipient, params)
        end
      end
    end

    def record
      params[:record]
    end
  end
end
