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

    # Slack's chat.postMessage endpoint returns a 200 with {ok: true/false}. Disable this check by setting to false
    # config.raise_if_not_ok = true
  end
end
```
