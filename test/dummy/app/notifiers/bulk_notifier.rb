class BulkNotifier < ApplicationNotifier
  bulk_deliver_by :webhook, url: "https://example.org/bulk"
end
