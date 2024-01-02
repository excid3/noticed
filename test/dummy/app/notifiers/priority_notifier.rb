class PriorityNotifier < Noticed::Event
  deliver_by :test, priority: 2
end
