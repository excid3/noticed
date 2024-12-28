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
    config.raise_on_failure = true # fail if response is 2xx but body['ok'] is false
  end
end
```
