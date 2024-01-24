class WaitUntilNotifier < ApplicationNotifier
  deliver_by :test, wait_until: -> { 1.hour.from_now }
end
