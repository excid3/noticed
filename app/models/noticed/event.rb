module Noticed
  class Event < ApplicationRecord
    include Deliverable
    include Translation
    include Rails.application.routes.url_helpers

    belongs_to :record, polymorphic: true, optional: true
    has_many :notifications, dependent: :delete_all

    attribute :params, default: {}
  end
end
