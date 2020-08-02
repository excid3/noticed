# Noticed - Notifications for your Ruby on Rails app.

[![Build Status](https://github.com/excid3/noticed/workflows/Tests/badge.svg)](https://github.com/excid3/noticed/actions)

Currently, we support these notification delivery methods out of the box:

* Database
* Email
* Websocket (realtime)
* Twilio (SMS)
* Vonage / Nexmo (SMS)

And you can easily add new notification types for any other delivery methods.

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'noticed'
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install noticed
```

## Usage

You can define a Notification as a class that inherits from Noticed::Base. To add delivery methods, simply `include` the module for the delivery methods you would like to use.

```ruby
class CommentNotification < Noticed::Base
  deliver_by :database
  deliver_by :action_cable
end
```

To send a notification to a user:

```ruby
notification = CommentNotification.with(comment: @comment.to_gid)

# Deliver notification in background job
notification.deliver_later(@comment.post.author)

# Deliver notification immediately
notification.deliver(@comment.post.author)
```

This will instantiate a new notification with the `comment` global ID stored in the metadata.

Each delivery method is able to transfrom this metadata that's best for the format. For example, the database may simply store the comment so it can be linked when rendering in the navbar. The websocket mechanism may transform this into a browser notification or insert it into the navbar.

## Delivery Methods

The delivery methods are designed to be overriden so that you can customi1ze the notification for each medium.

For example, emails will require a subject, body, and email address while an SMS requires a phone number and simple message. You can define the formats for each of these in your Notification and the delivery method will handle the processing of it.

#### Database

Writes notification to the database.

`deliver_by :database`

**Note:** Database notifications are special in that they will run before the other delivery methods. We do this so you can reference the database record ID in other delivery methods.

#### Email

Sends an email notification.

`deliver_by :email, mailer: "UserMailer"`

Requires the `mailer` option to be passed in.

You can also pass in a `method: :invoice_paid` option to specify the method on the mailer to be called

Emails will always be sent with `deliver_later

#### Slack

Sends a Slack notification via webhook.

`deliver_by :slack`

#### Twilio SMS

Sends an SMS notification via Twilio.

`deliver_by :twilio`

#### Vonage SMS

Sends an SMS notification vai Vonage / Nexmo.

`deliver_by :vonage`

#### ActionCable

Sends a notification to the browser via websockets (ActionCable channel by default).

`deliver_by :action_cable`

### User Preferences

Each delivery method implements a `deliver_with_#{name}` method that receives the recipient as the first argument. You can override this method to check the user's preferences and skip processing if they have disabled that type of notification.

For example:

```ruby
class CommentNotification < Noticed::Base
  deliver_by :email, if: :email_notifications?

  def email_notifications?
    recipient.email_notifications?
  end
end
```

### Custom Delivery Methods

You can define a custom delivery method easily by adding a `deliver_by` line with a unique name and class option. The class will be instantiated and should inherit from `Noticed::DeliveryMethods::Base`.

```ruby
class MyNotification < Noticed::Base
  deliver_by :discord, class: "DiscordNotification"
end
```

```ruby
class DiscordNotification < Noticed::DeliveryMethods::Base
  def deliver
    # Logic for sending a Discord notification
  end
end
```

Delivery methods have access to the following methods and attributes:

* `notification` - The instance of the Notification. You can call methods on the notification to let the user easily override formatting and other functionality of the delivery method.
* `options` - Any configuration options on the `deliver_by` line.
* `recipient` - The object who should receive the notification. This is typically a User, Account, or other ActiveRecord model.
* `params` - The params passed into the notification. This is details about the event that happened. For example, a user commenting on a post would have params of `{ user: User.first }`

#### Limitations

Rails 6.1+ can serialize Class and Module objects as arguments to ActiveJob. The following syntax should work for Rails 6.1+:

```ruby
  deliver_by DiscordNotification
```

For Rails 6.0 and earlier, you must pass strings of the class names in the `deliver_by` options.

```ruby
  deliver_by :discord, class: "DiscordNotification"
```

We recommend the Rails 6.0 compatible options to prevent confusion.

## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
