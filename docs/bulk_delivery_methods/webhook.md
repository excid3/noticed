# Webhook Bulk Delivery Method

Send a webhook request to bulk notify users in a channel.

## Usage

```ruby
class CommentNotification
  bulk_deliver_by :webhook do |config|
    config.url = "https://example.org..."
    config.json = -> {
      {
        # ...
      }
    }
  end
end
```
