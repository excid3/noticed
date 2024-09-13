# Slack Bulk Delivery Method

Send a Slack message to bulk notify users in a channel.

## Usage

```ruby
class CommentNotification
  bulk_deliver_by :slack do |config|
    config.url = "https://slack.com..."
    config.json = -> {
      {
        # ...
      }
    }
  end
end
```
