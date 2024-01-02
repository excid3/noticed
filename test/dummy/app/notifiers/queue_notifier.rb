class QueueNotifier < Noticed::Event
  deliver_by :test, queue: :example_queue
end
