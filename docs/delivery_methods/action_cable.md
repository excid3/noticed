### ActionCable Delivery Method

Sends a notification to the browser via websockets (ActionCable channel by default).

`deliver_by :action_cable`

##### Options

* `format: :format_for_action_cable` - *Optional*

  Use a custom method to define the Hash sent through ActionCable

* `channel` - *Optional*

  Override the ActionCable channel used to send notifications.

  Defaults to `Noticed::NotificationChannel`

* `stream` - *Optional*

  Overrides the stream that is broadcasted to.

  Defaults to `recipient`

```ruby
deliver_by :action_cable, channel: MyChannel, stream: :custom_stream, format: :action_cable_data
def custom_stream
  "user_#{recipient.id}"
end
def action_cable_data
  { user_id: recipient.id }
end
```
