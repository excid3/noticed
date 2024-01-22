# iOS Notification Delivery Method

Send Apple Push Notifications with HTTP2 using the `apnotic` gem. The benefit of HTTP2 is that we can receive feedback for invalid device tokens without running a separate feedback service like RPush does.

```bash
bundle add "apnotic"
```

## Apple Push Notification Service (APNS) Authentication

Token-based authentication is used for APNS.
* A single key can be used for every app in your developer account.
* Token authentication never expires, unlike certificate authentication which must be renewed annually.

Follow these docs for setting up Token-based authentication.
https://github.com/ostinelli/apnotic#token-based-authentication
https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/establishing_a_token-based_connection_to_apns

## Usage

```ruby
class CommentNotification
  deliver_by :ios do |config|
    config.device_tokens = ->(recipient) { recipient.notification_tokens.where(platform: :iOS).pluck(:token) }
    config.format = ->(apn) {
      apn.alert = "Hello world"
      apn.custom_payload = {url: root_url(host: "example.org")}
    }
    config.bundle_identifier = Rails.application.credentials.dig(:ios, :bundle_id)
    config.key_id = Rails.application.credentials.dig(:ios, :key_id)
    config.team_id = Rails.application.credentials.dig(:ios, :team_id)
    config.apns_key = Rails.application.credentials.dig(:ios, :apns_key)
  end
end
```

## Options

* `json`

  Customize the Apnotic notification object

  See https://github.com/ostinelli/apnotic#apnoticnotification

* `bundle_identifier`

  The APN bundle identifier

* `apns_key`

  The contents of your p8 apns key file.

* `key_id`

  Your APN Key ID

* `team_id`

  Your APN Team ID

* `pool_size: 5` - *Optional*

  The connection pool size for Apnotic

* `development` - *Optional*

  Set this to `true` to use the APNS sandbox environment for sending notifications. This is required when running the app to your device via Xcode. Running the app via TestFlight or the App Store should not use development.

## Gathering Notification Tokens

A recipient can have multiple tokens (i.e. multiple iOS devices), so make sure to return them all.

Here, the recipient `has_many :notification_tokens` with columns `platform` and `token`.

```ruby
deliver_by :ios do |config|
  config.device_tokens = ->(recipient) { recipient.notification_tokens.where(platform: :iOS).pluck(:token) }
end
```

## Handling Failures

Apple Push Notifications may fail delivery if the user has removed the app from their device. Noticed allows you

```ruby
class CommentNotification
  deliver_by :ios do |config|
    config.invalid_token = ->(token) { NotificationToken.where(token: token).destroy_all }
  end
end
```

## Delivering to Sandboxes and real devices

If you wish to send notifications to both sandboxed and real devices from the same application, you can configure two iOS delivery methods
A user has_many tokens that can be generated from both development (sandboxed devices), or production (not sandboxed devices) and is unrelated to the rails environment or endpoint being used. I

```ruby
deliver_by :ios do |config|
 config.device_tokens = ->(recipient) { recipient.notification_tokens.where(environment: :production, platform: :iOS).pluck(:token) }
end

deliver_by :ios_development, class: "Noticed::DeliveryMethods::Ios" do |config|
  config.development = true
  config.device_tokens = ->(recipient) { recipient.notification_tokens.where(environment: :development, platform: :iOS).pluck(:token) }
end
```
