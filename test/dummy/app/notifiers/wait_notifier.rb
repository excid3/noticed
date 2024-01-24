class WaitNotifier < ApplicationNotifier
  deliver_by :test, wait: 5.minutes
end
