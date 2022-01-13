# Firebase Cloud Messaging Delivery Method

Send Android Device Notifications using the Google Firebase Cloud Messaging service and the `googleauth` gem.

```bash
bundle add "googleauth"
```

## Google Firebase Cloud Messaging Notification Service

To generate your Firebase Cloud Messaging credentials, you'll need to create your project if you have not already. See https://console.firebase.google.com/u/1/
Once you have created your project, visit the project dashboard and click the settings cog in the top of the left sidebar menu, then click project settings.
In the project settings screen click on the Service accounts tab in the top navigation menu, then click the Generate new private key button.
This json file will contain the necessary credentials in order to send notifications via Google Firebase Cloud Messaging.
See the below instructions on where to store this information within your application.

## Usage

```ruby
class CommentNotification
  deliver_by :fcm
end
```

With custom configuration:

```ruby
class CommentNotification
  deliver_by :fcm, credentials: :fcm_credentials, format: :format_notification

  # Customize notification
  def fcm_credentials
    Rails.root.join("config/certs/fcm.json")
  end

  def format_notification(device_token)
    {
      token: device_token,
      notification: {
        title: "Test Title",
        body: "Test body"
      }
    }
  end
end
```

## Options

* `format: :format_notification` - *Optional*

  Customize the Firebase Cloud Messaging notification object

* `credentials: :fcm_credentials` - *Optional*

  The location of your Firebase Cloud Messaging credentials.
  This can also accept a String object, which is the path to your credentials `"config/certs/fcm.json"` for example. Interally, this string is passed to `Rails.root.join()` as an argument so there is no need to do this beforehand.
  As well as a Hash which contains your credentials or a Symbol which points to a method which returns a Hash of your credentials
  Otherwise, if this option is left out, it will look for your credentials in `Rails.application.credentials.fcm`

## Gathering Notification Tokens

A recipient can have multiple tokens (i.e. multiple Android devices), so make sure to return them all.

Here, the recipient `has_many :notification_tokens` with columns `platform` and `token`.

```ruby
def fcm_device_tokens(recipient)
  recipient.notification_tokens.where(platform: "fcm").pluck(:token)
end
```

## Handling Failures

Firebase Cloud Messaging Notifications may fail delivery if the user has removed the app from their device. Noticed allows you

```ruby
class CommentNotification
  deliver_by :fcm

  # Remove invalid device tokens
  #
  # token - the device token from iOS or Android
  # platform - "iOS" or "Android"
  def cleanup_device_token(token:, platform:)
    NotificationToken.where(token: token, platform: platform).destroy_all
  end
end
```
