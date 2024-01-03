# Discord Bulk Delivery Method

Send a Discord message to builk notify users in a channel.

We recommend using [Discohook](https://discohook.org) to design your messages.

## Usage

```ruby
class CommentNotification
  bulk_deliver_by :discord do |config|
    config.url = "https://discord.com..."
    config.json = -> {
      {
        # ...
      }
    }
  end
end
```
