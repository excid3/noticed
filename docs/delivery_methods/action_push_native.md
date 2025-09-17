# Action Push Native Notification Delivery Method

Send Apple and Android push notifications with [Action Push Native](https://github.com/rails/action_push_native)

## Usage

```ruby
class CommentNotifier < ApplicationNotifier
  deliver_by :action_push_native do |config|
    config.devices = -> { ApplicationPushDevice.where(owner: recipient) }
    config.format = -> {
      {
        title: "Hello world, #{recipient.first_name}!",
        body: "Welcome to Noticed with Action Push Native.",
        badge: 1
      }
    }
    config.apple_data = -> {
      { category: "observable" }
    }
    config.google_data = -> {
      { }
    }
  end
end
```

## Options

* `devices`

  Should return a list of `ApplicationPushDevice` records

* `format`

  Should return a `Hash` of [Notification attributes](https://github.com/rails/action_push_native/tree/main?tab=readme-ov-file#actionpushnativenotification-attributes)

* `data`

  Should return a `Hash` of custom data to be sent with the notification

* `apple_data`

  Should return a `Hash` of APNS specific data

* `google_data`

  Should return a `Hash` of FCM specific data
