# Telegram Delivery Method

Send a Telegram message via the Telegram Bot API to individual recipients.

**Note:** If you want to send to a channel or group without recipients, use [`bulk_deliver_by :telegram`](../bulk_delivery_methods/telegram.md) instead.

## Getting a Bot Token

1. Open Telegram and search for [@BotFather](https://t.me/botfather)
2. Send `/newbot` and follow the instructions
3. Copy the bot token provided
4. Store it securely (e.g., in Rails credentials)

## Getting a Chat ID

- **For personal chats**: Start a conversation with your bot, then visit `https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getUpdates` and look for the `chat.id` in the response
- **For groups**: Add your bot to the group, then use the same method above
- **For channels**: Use the channel username (e.g., `@mychannel`) or the numeric channel ID (prefixed with `-100`)

## Usage

```ruby
class CommentNotifier < Noticed::Event
  deliver_by :telegram do |config|
    config.bot_token = "YOUR_BOT_TOKEN"
    config.chat_id = "CHAT_ID"
    # config.chat_id = -> { recipient.telegram_chat_id }
    config.text = -> { message }

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
- `chat_id` - The chat ID where the message should be sent (can be a user ID, group ID, or channel username)

## Optional Options

- `text` - The message text to send. Either `text` must be provided or `json` must include a `text` field. If `json` is provided without `text` in the config, the `json` payload should include the `text` field.
- `parse_mode` - Set to "HTML", "Markdown", or "MarkdownV2" for text formatting
- `disable_web_page_preview` - Set to `true` to disable link previews
- `disable_notification` - Set to `true` to send silently
- `json` - Custom JSON payload that will be merged with required fields (chat_id, text)
- `raise_if_not_ok` - Set to `false` to disable error checking for unsuccessful responses (defaults to `true`)

## Examples

### Basic Usage

```ruby
class AlertNotifier < Noticed::Event
  deliver_by :telegram do |config|
    config.bot_token = Rails.application.credentials.dig(:telegram, :bot_token)
    config.chat_id = -> { recipient.telegram_chat_id }
    config.text = -> { "Alert: #{params[:message]}" }
  end
end
```

### With Formatting

```ruby
class CommentNotifier < Noticed::Event
  deliver_by :telegram do |config|
    config.bot_token = "YOUR_BOT_TOKEN"
    config.chat_id = -> { recipient.telegram_chat_id }
    config.text = -> { "New comment: <b>#{params[:comment].body}</b>" }
    config.parse_mode = "HTML"
  end
end
```

### With Inline Keyboard

```ruby
class OrderNotifier < Noticed::Event
  deliver_by :telegram do |config|
    config.bot_token = "YOUR_BOT_TOKEN"
    config.chat_id = -> { recipient.telegram_chat_id }
    config.text = -> { "New order received!" }
    config.json = -> {
      {
        reply_markup: {
          inline_keyboard: [
            [{ text: "View Order", url: order_url(record) }]
          ]
        }
      }
    }
  end
end
```
