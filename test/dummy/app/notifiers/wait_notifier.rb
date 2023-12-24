class WaitNotifier < Noticed::Event
  deliver_by :test, wait: 5.minutes
end
