# iOS Notification Delivery Method

Send Apple Push Notifications with HTTP2 using the `apnotic` gem. The benefit of HTTP2 is that we can receive feedback for invalid device tokens without running a separate feedback service like RPush does.

```bash
bundle add "apnotic"
```

## Usage

```ruby
class CommentNotification
  deliver_by :ios
end
```

With custom configuration:

```ruby
class CommentNotification
  deliver_by :ios, format: :ios_format, cert_path: :ios_cert_path, key_id: :ios_key_id, team_id: :ios_team_id, pool_size: 5

  # Customize notification
  # See https://github.com/ostinelli/apnotic#apnoticnotification
  def ios_format(apn)
    apn.alert = "Hello world"
    apn.custom_payload = { url: root_url }
  end

  def ios_cert_path
    Rails.root.join("config/certs/ios/apns.p8")
  end

  def ios_key_id
    Rails.application.credentials.dig(:ios, :key_id)
  end

  def ios_team_id
    Rails.application.credentials.dig(:ios, :team_id)
  end
end
```

## Options

* `format: :ios_format` - *Optional*

  Customize the Apnotic notification object

  See https://github.com/ostinelli/apnotic#apnoticnotification

* `bundle_identifier: Rails.application.credentials.dig(:ios, :bundle_identifier)` - *Optional*

  The APN bundle identifier

* `cert_path: Rails.root.join("config/certs/ios/apns.p8")` - *Optional*

  The location of your APNs p8 certificate

* `key_id: Rails.application.credentials.dig(:ios, :key_id)` - *Optional*

  Your APN Key ID

  If nothing passed, we'll default to `Rails.application.credentials.dig(:ios, :key_id)`
  If a String is passed, we'll use that as the key ID.
  If a Symbol is passed, we'll call the matching method and you can return the Key ID.

* `team_id: Rails.application.credentials.dig(:ios, :team_id)` - *Optional*

  Your APN Team ID

  If nothing passed, we'll default to `Rails.application.credentials.dig(:ios, :team_id)`
  If a String is passed, we'll use that as the team ID.
  If a Symbol is passed, we'll call the matching method and you can return the team ID.

* `pool_size: 5` - *Optional*

  The connection pool size for Apnotic

## Handling Failures

Apple Push Notifications may fail delivery if the user has removed the app from their device. Noticed allows you

```ruby
class CommentNotification
  deliver_by :ios

  # Remove invalid device tokens
  #
  # token - the device token from iOS or Android
  # platform - "iOS" or "Android"
  def cleanup_device_token(token:, platform:)
    NotificationToken.where(token: token, platform: platform).destroy_all
  end
end
```
