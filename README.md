<p align="center">
  <h1>Noticed</h1>
</p>

### 🎉  Notifications for your Ruby on Rails app.

[![Build Status](https://github.com/excid3/noticed/workflows/Tests/badge.svg)](https://github.com/excid3/noticed/actions) [![Gem Version](https://badge.fury.io/rb/noticed.svg)](https://badge.fury.io/rb/noticed)

Currently, we support these notification delivery methods out of the box:

* Database
* Email
* ActionCable channels
* Slack
* Microsoft Teams
* Twilio (SMS)
* Vonage / Nexmo (SMS)
* iOS Apple Push Notifications
* Firebase Cloud Messaging (Android and more)

And you can easily add new notification types for any other delivery methods.

## 🎬 Screencast

<div style="width:50%">
  <a href="https://www.youtube.com/watch?v=Scffi4otlFc"><img src="https://i.imgur.com/UvVKWwD.png" title="How to add Notifications to Rails with Noticed" /></a>
</div>

[Watch Screencast](https://www.youtube.com/watch?v=Scffi4otlFc)

## 🚀 Installation
Run the following command to add Noticed to your Gemfile

```ruby
bundle add "noticed"
```

To save notifications to your database, use the following command to generate a Notification model.

```ruby
rails generate noticed:model
```

This will generate a Notification model and instructions for associating User models with the notifications table.

## 📝 Usage

To generate a notification object, simply run:

`rails generate noticed:notification CommentNotification`

#### Sending Notifications

To send a notification to a user:

```ruby
# Instantiate a new notification
notification = CommentNotification.with(comment: @comment)

# Deliver notification in background job
notification.deliver_later(@comment.post.author)

# Deliver notification immediately
notification.deliver(@comment.post.author)

# Deliver notification to multiple recipients
notification.deliver_later(User.all)
```

This will instantiate a new notification with the `comment` stored in the notification's params.

Each delivery method is able to transform this metadata that's best for the format. For example, the database may simply store the comment so it can be linked when rendering in the navbar. The websocket mechanism may transform this into a browser notification or insert it into the navbar.

#### Notification Objects

Notifications inherit from `Noticed::Base`. This provides all their functionality and allows them to be delivered.

To add delivery methods, simply `include` the module for the delivery methods you would like to use.

```ruby
class CommentNotification < Noticed::Base
  deliver_by :database
  deliver_by :action_cable
  deliver_by :email, mailer: 'CommentMailer', if: :email_notifications?

  # I18n helpers
  def message
    t(".message")
  end

  # URL helpers are accessible in notifications
  # Don't forget to set your default_url_options so Rails knows how to generate urls
  def url
    post_path(params[:post])
  end

  def email_notifications?
    !!recipient.preferences[:email]
  end

  after_deliver do
    # Anything you want
  end
end
```

**Shared Options**

* `if: :method_name`  - Calls `method_name` and cancels delivery method if `false` is returned
* `unless: :method_name`  - Calls `method_name` and cancels delivery method if `true` is returned
* `delay: ActiveSupport::Duration` - Delays the delivery for the given duration of time
* `delay: :method_name` - Calls `method_name` which should return an `ActiveSupport::Duration` and delays the delivery for the given duration of time

##### Helper Methods

You can define helper methods inside your Notification object to make it easier to render.

##### URL Helpers

Rails url helpers are included in notification classes by default so you have full access to them just like you would in your controllers and views.

Don't forget, you'll need to configure `default_url_options` in order for Rails to know what host and port to use when generating URLs.

```ruby
Rails.application.routes.default_url_options[:host] = 'localhost:3000'
```

**Callbacks**

Like ActiveRecord, notifications have several different types of callbacks.

```ruby
class CommentNotification < Noticed::Base
  deliver_by :database
  deliver_by :email, mailer: 'CommentMailer'

  # Callbacks for the entire delivery
  before_deliver :whatever
  around_deliver :whatever
  after_deliver :whatever

  # Callbacks for each delivery method
  before_database :whatever
  around_database :whatever
  after_database :whatever

  before_email :whatever
  around_email :whatever
  after_email :whatever
end
```

When using `deliver_later` callbacks will be run around queuing the delivery method jobs (not inside the jobs as they actually execute).

Defining custom delivery methods allows you to add callbacks that run inside the background job as each individual delivery is executed. See the Custom Delivery Methods section for more information.

##### Translations

We've added `translate` and `t` helpers like Rails has to provide an easy way of scoping translations. If the key starts with a period, it will automatically scope the key under `notifications` and the underscored name of the notification class it is used in.

For example:

 `t(".message")` looks up `en.notifications.new_comment.message`

Or when notification class is in module:

`t(".message") # in Admin::NewComment` looks up `en.notifications.admin.new_comment.message`

##### User Preferences

You can use the `if:` and `unless: ` options on your delivery methods to check the user's preferences and skip processing if they have disabled that type of notification.

For example:

```ruby
class CommentNotification < Noticed::Base
  deliver_by :email, mailer: 'CommentMailer', if: :email_notifications?

  def email_notifications?
    recipient.email_notifications?
  end
end
```

## 🐞 Debugging

In order to figure out what's up when you run in to errors, you can set the `debug` parameter to `true` in your notification, which will give you a more detailed error message about what went wrong.

Example:

```ruby
deliver_by :slack, debug: true
```

## ✅ Best Practices

### Creating a notification from an Active Record callback

A common use case is to trigger a notification when a record is created. For example,

```ruby
class Message < ApplicationRecord
  belongs_to :recipient, class_name: "User"

  after_create_commit :notify_recipient

  private

  def notify_recipient
    NewMessageNotification.with(message: self).deliver_later(recipient)
  end
```

If you are creating the notification on a background job (i.e. via `#deliver_later`), make sure you use a `commit` hook such as `after_create_commit` or `after_commit`.

Using `after_create` might cause the notification delivery methods to fail. This is because the job was enqueued while inside a database transaction, and the `Message` record might not yet be saved to the database.

A common symptom of this problem is undelivered notifications and the following error in your logs.

> `Discarded Noticed::DeliveryMethods::Email due to a ActiveJob::DeserializationError.`

### Renaming notifications

If you rename the class of a notification object your existing queries can break. This is because Noticed serializes the class name and sets it to the `type` column on the `Notification` record.

You can catch these errors at runtime by using `YourNotificationClassName.name` instead of hardcoding the string when performing a query.

```ruby
Notification.where(type: YourNotificationClassName.name) # good
Notification.where(type: "YourNotificationClassName") # bad
```

When renaming a notification class you will need to backfill existing notifications to reference the new name.

```ruby
Notification.where(type: "OldNotificationClassName").update_all(type: NewNotificationClassName.name)
```

## 🚛 Delivery Methods

The delivery methods are designed to be modular so you can customize the way each type gets delivered.

For example, emails will require a subject, body, and email address while an SMS requires a phone number and simple message. You can define the formats for each of these in your Notification and the delivery method will handle the processing of it.

* [Database](docs/delivery_methods/database.md)
* [Email](docs/delivery_methods/email.md)
* [ActionCable](docs/delivery_methods/action_cable.md)
* [iOS Apple Push Notifications](docs/delivery_methods/ios.md)
* [Microsoft Teams](docs/delivery_methods/microsoft_teams.md)
* [Slack](docs/delivery_methods/slack.md)
* [Test](docs/delivery_methods/test.md)
* [Twilio](docs/delivery_methods/twilio.md)
* [Vonage](docs/delivery_methods/vonage.md)
* [Firebase Cloud Messaging](docs/delivery_methods/fcm.md)

### Fallback Notifications

A common pattern is to deliver a notification via the database and then, after some time has passed, email the user if they have not yet read the notification. You can implement this functionality by combining multiple delivery methods, the `delay` option, and the conditional `if` / `unless` option.

```ruby
class CommentNotification < Noticed::Base
  deliver_by :database
  deliver_by :email, mailer: 'CommentMailer', delay: 15.minutes, unless: :read?
end
```

Here a notification will be created immediately in the database (for display directly in your app). If the notification has not been read after 15 minutes, the email notification will be sent. If the notification has already been read in the app, the email will be skipped.

You can also configure multiple fallback options:

```ruby
class CriticalSystemNotification < Noticed::Base
  deliver_by :database
  deliver_by :slack
  deliver_by :email, mailer: 'CriticalSystemMailer', delay: 10.minutes, if: :unread?
  deliver_by :twilio, delay: 20.minutes, if: :unread?
end
```

In this scenario, you have created an escalating notification system that

-  Immediately creates a record in the database (for display directly in the app)
-  Immediately issues a ping in Slack.
-  If the notification remains unread after 10 minutes, it emails the team.
-  If the notification remains unread after 20 minutes, it sends an SMS to the on-call phone.

You can mix and match the options and delivery methods to suit your application specific needs.

Please note that to implement this pattern, it is essential `deliver_by :database` is one among the different delivery methods specified. Without this, a database record of the notification will not be created.

### 🚚 Custom Delivery Methods

To generate a custom delivery method, simply run

`rails generate noticed:delivery_method Discord`

This will generate a new `DeliveryMethods::Discord` class inside the `app/notifications/delivery_methods` folder, which can be used to deliver notifications to Discord.

```ruby
class DeliveryMethods::Discord < Noticed::DeliveryMethods::Base
  def deliver
    # Logic for sending a Discord notification
  end
end
```

You can use the custom delivery method thus created by adding a `deliver_by` line with a unique name and `class` option in your notification class.

```ruby
class MyNotification < Noticed::Base
  deliver_by :discord, class: "DeliveryMethods::Discord"
end
```

Delivery methods have access to the following methods and attributes:

* `notification` - The instance of the Notification. You can call methods on the notification to let the user easily override formatting and other functionality of the delivery method.
* `options` - Any configuration options on the `deliver_by` line.
* `recipient` - The object who should receive the notification. This is typically a User, Account, or other ActiveRecord model.
* `params` - The params passed into the notification. This is details about the event that happened. For example, a user commenting on a post would have params of `{ user: User.first }`

#### Validating options passed to Custom Delivery methods

The presence of the delivery method options is automatically validated if using the `option(s)` method.

If you want to validate that the passed options contain valid values, or to add any custom validations, override the `self.validate!(delivery_method_options)` method from the `Noticed::DeliveryMethods::Base` class.

```ruby
class DeliveryMethods::Discord < Noticed::DeliveryMethods::Base
  option :username # Requires the username option to be passed

  def deliver
    # Logic for sending a Discord notification
  end

  def self.validate!(delivery_method_options)
    super # Don't forget to call super, otherwise option presence won't be validated

    # Custom validations
    if delivery_method_options[:username].blank?
      raise Noticed::ValidationError, 'the `username` option must be present'
    end
  end
end

class CommentNotification < Noticed::Base
  deliver_by :discord, class: 'DeliveryMethods::Discord'
end
```

Now it will raise an error because a required argument is missing.

To fix the error, the argument has to be passed correctly. For example:

```ruby
class CommentNotification < Noticed::Base
  deliver_by :discord, class: 'DeliveryMethods::Discord', username: User.admin.username
end
```

#### Callbacks

Callbacks for delivery methods wrap the *actual* delivery of the notification. You can use `before_deliver`, `around_deliver` and `after_deliver` in your custom delivery methods.

```ruby
class DeliveryMethods::Discord < Noticed::DeliveryMethods::Base
  after_deliver do
    # Do whatever you want
  end
end
```

### 📦 Database Model

The Notification database model includes several helpful features to make working with database notifications easier.

#### Class methods

Sorting notifications by newest first:

```ruby
user.notifications.newest_first
```

Query for read or unread notifications:

```ruby
user.notifications.read
user.notifications.unread
```


Marking all notifications as read or unread:

```ruby
user.notifications.mark_as_read!
user.notifications.mark_as_unread!
```

#### Instance methods

Convert back into a Noticed notification object:

```ruby
@notification.to_notification
```

Mark notification as read / unread:

```ruby
@notification.mark_as_read!
@notification.mark_as_unread!
```

Check if read / unread:

```ruby
@notification.read?
@notification.unread?
```

#### Associating Notifications

Adding notification associations to your models makes querying and deleting notifications easy and is a pretty critical feature of most applications.

For example, in most cases, you'll want to delete notifications for records that are destroyed.

We'll need two associations for this:

1. Notifications where the record is the recipient
2. Notifications where the record is in the notification params

For example,  we can query the notifications and delete them on destroy like so:

```ruby
class Post < ApplicationRecord
  # Standard association for deleting notifications when you're the recipient
  has_many :notifications, as: :recipient, dependent: :destroy

  # Helper for associating and destroying Notification records where(params: {post: self})
  has_noticed_notifications

  # You can override the param_name, the notification model name, or disable the before_destroy callback
  has_noticed_notifications param_name: :parent, destroy: false, model_name: "Notification"
end

# Create a CommentNotification with a post param
CommentNotification.with(post: @post).deliver(user)
# Lookup Notifications where params: {post: @post}
@post.notifications_as_post

CommentNotification.with(parent: @post).deliver(user)
@post.notifications_as_parent
```

#### Handling Deleted Records

If you create a notification but delete the associated record and forgot `has_noticed_notifications` on the model, the jobs for sending the notification will not be able to find the record when ActiveJob deserializes. You can discard the job on these errors by adding the following to `ApplicationJob`:

```ruby
class ApplicationJob < ActiveJob::Base
  discard_on ActiveJob::DeserializationError
end
```

## 🙏 Contributing

This project uses [Standard](https://github.com/testdouble/standard) for formatting Ruby code. Please make sure to run `standardrb` before submitting pull requests.

Running tests against multiple databases locally:

```
DATABASE_URL=sqlite3:noticed_test rails test
DATABASE_URL=mysql2://root:@127.0.0.1/noticed_test rails test
DATABASE_URL=postgres://127.0.0.1/noticed_test rails test
```

## 📝 License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
