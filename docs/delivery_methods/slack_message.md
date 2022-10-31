# Slack Message Delivery Method

Sends a Slack Message notification. Using `chat.postMessage` API call it allows you to interact with Slack by tokens obtained from OAuth2 flow. In this case you can message to users, channels or apps, while [webhooks](https://github.com/excid3/noticed/blob/master/docs/delivery_methods/slack.md) only you allow to communicate to channel where webhook is installed.

```ruby
deliver_by :slack_message
```
## Usage

To be able to use [`chat.postMessage`](https://api.slack.com/methods/chat.postMessage) Slack API method you should have `slack_token` and `slack_channel` methods defined.

* `slack_token` should return a valid Slack API token, usually it is aquired via Slack OAuth 2 flow.
* `slack_channel` should return ID of a private group, or IM channel to send message to. Can be an encoded ID, or a name.

```ruby
class CommentNotification
  deliver_by :slack_message, text: 'Hello'

  def slack_token
    Authorization::Slack.find_by(member: recipient).token
  end

  def slack_channel
    Authorization::Slack.find_by(member: recipient).channel
  end
end
```

In the example above `Authorization::Slack` is an ActiveRecord object that stores result of OAuth2 Slack flow.

## Options

You can pass data to Slack Messages with either using options of `deliver_by` method (in this case at least one of `attachments`, `blocks` or `text` params should be present) or by using `format` option.

```ruby
class CommentNotification
  deliver_by :slack_message, format: :format_slack_message

  # ...

  def format_slack_message
    {
      text: "Hello #{recipient.first_name}"
    }
  end
end
```

In this case `recipient` will be an object that you pass to `deliver` method.

```ruby
CommentNotification.new.deliver(User.first)
```



