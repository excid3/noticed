module Noticed
  class Notification < ApplicationRecord
    include Translation
    include Rails.application.routes.url_helpers

    belongs_to :event
    belongs_to :recipient, polymorphic: true

    delegate :params, :record, to: :event

    attribute :params, default: {}
  end
end
