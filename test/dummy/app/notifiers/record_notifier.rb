class RecordNotifier < Noticed::Event
  validates :record, presence: true
end
