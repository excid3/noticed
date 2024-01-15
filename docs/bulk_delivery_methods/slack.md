# Slack Bulk Delivery Method

Send a Slack message to builk notify users in a channel.

## Usage

```ruby
class CommentNotification
  deliver_by :slackdo |config|
    config.url = "https://slack.com..."
    config.json = -> {
      {
        # ...
      }
    }
  end
end
```
