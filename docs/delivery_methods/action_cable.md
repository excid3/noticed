# ActionCable Delivery Method

Sends a notification to the browser via websockets (ActionCable channel by default).

```ruby
deliver_by :action_cable do |config|
  config.channel = "NotificationsChannel"
  config.stream = :custom_stream
  config.message = ->{ params.merge( user_id: recipient.id) }
end
```

## Options

* `format: :format_for_action_cable` - *Optional*

  Use a custom method to define the Hash sent through ActionCable

* `channel` - *Optional*

  Override the ActionCable channel used to send notifications.

  Defaults to `Noticed::NotificationChannel`

* `stream` - *Optional*

  Overrides the stream that is broadcasted to.

  Defaults to `recipient`

## Authentication

To send notifications to individual users, you'll want to use `stream_for current_user`

```ruby
class NotificationChannel < ApplicationCable::Channel
  def subscribed
    stream_for current_user
  end

  def unsubscribed
    stop_all_streams
  end
end
```

This requires `identified_by :current_user` in your ApplicationCable::Connection. For example, using Devise for authentication:

```ruby
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
      logger.add_tags "ActionCable", "User #{current_user.id}"
    end

    protected

      def find_verified_user
        if current_user = env['warden'].user
          current_user
        else
          reject_unauthorized_connection
        end
      end
  end
end
```
