# ActionCable Notifications

ActionCable notifications in noticed are broadcast to the Noticed::NotificationChannel.

By default, we simply send over the `params` as JSON and subscribe to the `current_user` stream.

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

## Subscribing to the Noticed::NotificationChannel with Javascript

To receive Noticed notifications client-side, you'll need to subscribe to the Noticed::NotificationChannel.

```javascript
// app/javascript/channels/notification_channel.js

import consumer from "./consumer"

consumer.subscriptions.create("Noticed::NotificationChannel", {
  connected() {
    // Called when the subscription is ready for use on the server
  },

  disconnected() {
    // Called when the subscription has been terminated by the server
  },

  received(data) {
    // Called when there's incoming data on the websocket for this channel
    console.log(data)
  }
});
```

## References

ActionCable Delivery Method: https://github.com/excid3/noticed/blob/master/lib/noticed/delivery_methods/action_cable.rb
NotificationsChannel: https://github.com/excid3/noticed/blob/master/lib/noticed/notification_channel.rb
