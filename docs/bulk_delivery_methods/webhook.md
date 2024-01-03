# Webhook Bulk Delivery Method

Send a webhook request to builk notify users in a channel.

## Usage

```ruby
class CommentNotification
  deliver_by :webhook do |config|
    config.url = "https://example.org..."
    config.json = -> {
      {
        # ...
      }
    }
  end
end
```
