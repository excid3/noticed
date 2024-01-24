class RecordNotifier < ApplicationNotifier
  validates :record, presence: true
end
