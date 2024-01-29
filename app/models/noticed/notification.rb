module Noticed
  class Notification < ApplicationRecord
    include Rails.application.routes.url_helpers
    include Readable
    include Translation

    belongs_to :event, counter_cache: true
    belongs_to :recipient, polymorphic: true

    scope :newest_first, -> { order(created_at: :desc) }

    delegate :params, :record, to: :event
  end
end
