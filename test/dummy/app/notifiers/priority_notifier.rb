class PriorityNotifier < ApplicationNotifier
  deliver_by :test, priority: 2
end
