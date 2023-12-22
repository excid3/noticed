module Noticed
  class Notification < ApplicationRecord
    include Rails.application.routes.url_helpers
    include Readable
    include Translation

    belongs_to :event
    belongs_to :recipient, polymorphic: true

    delegate :params, :record, to: :event

    attribute :params, default: {}
  end
end
