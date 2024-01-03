# Discord Bulk Delivery Method

Send Discord messages to builk notify users in a channel.

We recommend using [Discohook](https://discohook.org) to design your messages.

## Usage

```ruby
class CommentNotification
  deliver_by :discord do |config|
    config.url = "https://discord.com..."
    config.json = -> {
      {
        # ...
      }
    }
  end
end
```
