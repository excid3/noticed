module Noticed
  class Event < ApplicationRecord
    include Deliverable
    include NotificationMethods
    include Translation
    include Rails.application.routes.url_helpers

    belongs_to :record, polymorphic: true, optional: true
    has_many :notifications, dependent: :delete_all

    accepts_nested_attributes_for :notifications

    scope :newest_first, -> { order(created_at: :desc) }

    attribute :params, :json, default: {}

    # Ephemeral notifiers cannot serialize params since they aren't ActiveRecord backed
    if respond_to? :serialize
      serialize :params, coder: Coder
    end
  end
end

ActiveSupport.run_load_hooks :noticed_event, Noticed::Event
