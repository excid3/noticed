module Noticed
  module Database
    extend ActiveSupport::Concern

    included do
      deliver_with :database, prepend: true
      attr_accessor :record
    end

    delegate :id, :created_at, :updated_at, :read_at, to: :record

    def deliver_with_database(recipient)
      @record = recipient.notifications.create(format_for_database(recipient))
    end

    def format_for_database(recipient)
      data
    end
  end
end
