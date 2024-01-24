class QueueNotifier < ApplicationNotifier
  deliver_by :test, queue: :example_queue
end
