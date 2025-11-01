# Telegram Bulk Delivery Method

Send a Telegram message to a channel or group (one message for all recipients).

**Note:** If you want to send individual messages to recipients, use [`deliver_by :telegram`](../delivery_methods/telegram.md) instead.

## Getting a Bot Token

1. Open Telegram and search for [@BotFather](https://t.me/botfather)
2. Send `/newbot` and follow the instructions
3. Copy the bot token provided
4. Store it securely (e.g., in Rails credentials)

## Getting a Chat ID

- **For channels**: Use the channel username (e.g., `@mychannel`) or get the numeric channel ID by forwarding a message from the channel to [@userinfobot](https://t.me/userinfobot)
- **For groups**: Add your bot to the group, then visit `https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getUpdates` and look for the `chat.id` in the response

## Usage

```ruby
class CommentNotifier < Noticed::Event
  bulk_deliver_by :telegram do |config|
    config.bot_token = "YOUR_BOT_TOKEN"
    config.chat_id = "@mychannel"  # or channel ID like "-1001234567890"
    config.text = -> { "New comment: #{params[:comment].body}" }

    # Optional: Telegram returns {ok: true/false}. Set to false to disable error checking
    # config.raise_if_not_ok = true

    # Optional: Parse mode (HTML, Markdown, or MarkdownV2)
    # config.parse_mode = "HTML"

    # Optional: Disable web page preview
    # config.disable_web_page_preview = true

    # Optional: Send silently (no notification sound)
    # config.disable_notification = true

    # Optional: Custom JSON payload (will be merged with required fields)
    # config.json = -> {
    #   {
    #     reply_markup: {
    #       inline_keyboard: [
    #         [{ text: "View", url: url }]
    #       ]
    #     }
    #   }
    # }
  end
end
```

## Required Options

- `bot_token` - Your Telegram bot token (obtained from [@BotFather](https://t.me/botfather))
- `chat_id` - The channel or group ID where the message should be sent (can be a channel username like `@mychannel` or numeric ID)

## Optional Options

- `text` - The message text to send. Either `text` must be provided or `json` must include a `text` field. If `json` is provided without `text` in the config, the `json` payload should include the `text` field.
- `parse_mode` - Set to "HTML", "Markdown", or "MarkdownV2" for text formatting
- `disable_web_page_preview` - Set to `true` to disable link previews
- `disable_notification` - Set to `true` to send silently
- `json` - Custom JSON payload that will be merged with required fields (chat_id, text)
- `raise_if_not_ok` - Set to `false` to disable error checking for unsuccessful responses (defaults to `true`)

## Examples

### Basic Channel Notification

```ruby
class OrderNotifier < Noticed::Event
  bulk_deliver_by :telegram do |config|
    config.bot_token = Rails.application.credentials.dig(:telegram, :bot_token)
    config.chat_id = "@mycompany_orders"
    config.text = -> { "New order received: #{params[:order].id}" }
  end
end

# Send to channel without needing recipients
OrderNotifier.with(order: order).deliver
```

### With Formatting

```ruby
class AlertNotifier < Noticed::Event
  bulk_deliver_by :telegram do |config|
    config.bot_token = "YOUR_BOT_TOKEN"
    config.chat_id = "-1001234567890"  # Channel ID
    config.text = -> { "🚨 Alert: <b>#{params[:message]}</b>" }
    config.parse_mode = "HTML"
  end
end
```
