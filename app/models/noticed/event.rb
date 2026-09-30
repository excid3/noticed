module Noticed
  class Event < ApplicationRecord
    include Deliverable
    include NotificationMethods
    include Translation
    include Rails.application.routes.url_helpers

    belongs_to :record, polymorphic: true, optional: true
    has_many :notifications, dependent: :delete_all

    scope :newest_first, -> { order(created_at: :desc) }

    attribute :params, :json, default: {}

    serialize :params, coder: Coder
  end
end

ActiveSupport.run_load_hooks :noticed_event, Noticed::Event
