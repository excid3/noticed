module Noticed
  class Event < ApplicationRecord
    include Deliverable
    include NotificationMethods
    include Translation
    include Rails.application.routes.url_helpers

    belongs_to :record, polymorphic: true, optional: true
    has_many :notifications, dependent: :delete_all

    attribute :params, default: {}
    accepts_nested_attributes_for :notifications

    scope :newest_first, -> { order(created_at: :desc) }
  end
end
