# Noticed 
### 🎉  Notifications for your Ruby on Rails app.

[![Build Status](https://github.com/excid3/noticed/workflows/Tests/badge.svg)](https://github.com/excid3/noticed/actions) [![Gem Version](https://badge.fury.io/rb/noticed.svg)](https://badge.fury.io/rb/noticed)

Noticed helps you send notifications in your Rails apps. Notifications can be sent to any number of recipients. You might want a Slack notification with 0 recipients to let your team know when something happens. A notification can also be sent to 1+ recipients with individual deliveries (like an email to each recipient).

The core concepts of Noticed are:

1. `Notifier` - Classes that define how notifications are delivered and when.
2. `Noticed::Event` - When a `Notifier` is delivered, a `Noticed::Event` record is created in the database to store params for the delivery.`Notifiers` are ActiveRecord objects inherited from `Noticed::Event` using Single Table Inheritance.
3. `Noticed::Notification` - Keeps track of each recipient for `Noticed::Event` and the seen & read status for each.
4. Delivery methods are ActiveJob instances and support the same features like wait, queue, and priority.

## Delivery Methods
Individual Delivery methods (one notification to each recipient):

* [ActionCable](docs/delivery_methods/action_cable.md)
* [Apple Push Notification Service](docs/delivery_methods/ios.md)
* [Email](docs/delivery_methods/email.md)
* [Firebase Cloud Messaging](docs/delivery_methods/fcm.md) (iOS, Android, and web clients)
* [Microsoft Teams](docs/delivery_methods/microsoft_teams.md)
* [Slack](docs/delivery_methods/slack.md)
* [Twilio Messaging](docs/delivery_methods/twilio_messaging.md) - SMS, Whatsapp
* [Vonage SMS](docs/delivery_methods/vonage_sms.md)
* [Test](docs/delivery_methods/test.md)

Bulk delivery methods (one notification for all recipients):

* [Discord](docs/bulk_delivery_methods/discord.md)
* [Slack](docs/bulk_delivery_methods/slack.md)
* [Webhook](docs/bulk_delivery_methods/webhook.md)

## 🎬 Screencast

<a href="https://www.youtube.com/watch?v=SzX-aBEqnAc"><img src="https://i.imgur.com/fOCvUh2.png" title="How to add Notifications to Rails with Noticed" width="50%" /></a>

[Watch Screencast](https://www.youtube.com/watch?v=SzX-aBEqnAc)

## 🚀 Installation
Run the following command to add Noticed to your Gemfile:

```ruby
bundle add "noticed"
```

Add the migrations:

```bash
rails noticed:install:migrations
rails db:migrate
```

## 📝 Usage

To generate a Notifier, simply run:

`rails generate noticed:notifier CommentNotifier`

#### Add Delivery Methods
Then add delivery methods to the Notifier. See [docs/delivery_methods](docs/) for a full list.

```ruby
# app/notifiers/comment_notifier.rb
class CommentNotifier < Noticed::Event
  bulk_deliver_by :webhook do |config|
    config.url = "https://example.org..."
    config.json = ->{ text: "New comment: #{record.body}" }
  end

  deliver_by :email do |config|
    config.mailer = "UserMailer"
    config.method = :new_comment
  end
end
```

#### Sending Notifications

To send a notification to user(s):

```ruby
# Instantiate a new notifier
CommentNotifier.with(record: @comment, foo: "bar").deliver_later(User.all)
```

This instantiates a new `CommentNotifier` with params. Similar to ActiveJob, you can pass any params can be serialized.  `record:` is a special param that gets assigned to the `record` polymorphic association in the database.

Delivering will create a `Noticed::Event` record and associated `Noticed::Notification` records for each recipient.

After saving, a job will be enqueued for processing this notification and delivering it to all recipients.

Each delivery method also spawns its own job. This allows you to skip email notifications if the user had already opened a push notification, for example.

#### Notifier Objects

Notifiers inherit from `Noticed::Event`. This provides all their functionality and allows them to be delivered.

```ruby
class CommentNotifier < Noticed::Event
  deliver_by :action_cable
  deliver_by :email do |config|
    config.mailer = "UserMailer"
    config.if = ->(recipient) { !!recipient.preferences[:email] }
    config.wait = 5.minutes
  end
end
```

**Shared Options**

* `if: :method_name`  - Calls `method_name` and cancels delivery method if `false` is returned. This can also be specified as a Proc / lambda.
* `unless: :method_name`  - Calls `method_name` and cancels delivery method if `true` is returned
* `wait:` - Delays the delivery for the given duration of time. Can be an `ActiveSupport::Duration`, Proc / lambda, or Symbol.

##### Helper Methods

You can define helper methods inside your Notifier object to make it easier to render.

```ruby
class CommentNotifier < Noticed::Event
  # I18n helpers
  def message
    t(".message")
  end

  # URL helpers are accessible in notifications
  # Don't forget to set your default_url_options so Rails knows how to generate urls
  def url
    post_path(params[:post])
  end

  # Defines methods added to the Noticed::Notification
  notification_methods do
    def personalized_welcome
      "Hello #{recipient.first_name}."
    end
  end
end
```

In your views, you can loop through notifications and access
```erb
<%= current_user.notifications.includes(:event).each do |notification| %>
  <%= link_to notification.personalized_welcome, notification.event.url %>
<% end %>
```

##### URL Helpers

URL helpers are included in Notifier classes so you have full access to them just like in your controllers and views. Configure `default_url_options` in order for Rails to know what host and port to use when generating URLs.

```ruby
Rails.application.routes.default_url_options[:host] = 'localhost:3000'
```

##### Translations

`translate` and `t` helpers are available in Notifiers. If the key starts with a period, it will automatically scope the key under `notifiers` and the underscored name of the notification class it is used in.

For example:

`t(".message")` looks up `en.notifiers.new_comment.message`
`t(".message") # in Admin::NewComment` looks up `en.notifiers.admin.new_comment.message`

##### User Preferences

You can use the `if:` and `unless: ` options on your delivery methods to check the user's preferences and skip processing if they have disabled that type of notification.

For example:

```ruby
class CommentNotifier < Noticed::Base
  deliver_by :email do |config|
    config.mailer = 'CommentMailer'
    config.method = :new_comment
    config.if = ->{ recipient.email_notifications? }
  end
end
```

## ✅ Best Practices

### Creating a notification from an Active Record callback

Always use `after_commit` hooks to send notifications from ActiveRecord callbacks. For example, to send a notification automatically after a message is created:

```ruby
class Message < ApplicationRecord
  belongs_to :recipient, class_name: "User"

  after_create_commit :notify_recipient

  private

  def notify_recipient
    NewMessageNotifier.with(message: self).deliver_later(recipient)
  end
```

Using `after_create` might cause the notification delivery methods to fail. This is because the job was enqueued while inside a database transaction, and the `Message` record might not yet be saved to the database.

A common symptom of this problem is undelivered notifications and the following error in your logs.

> `Discarded Noticed::DeliveryMethods::Email due to a ActiveJob::DeserializationError.`

### Renaming Notifiers

If you rename the class of a notification object your existing queries can break. This is because ActiveRecord serializes the class name and sets it to the `type` column on the Noticed records.

You can catch these errors at runtime by using `YourNotifierClassName.name` instead of hardcoding the string when performing a query.

```ruby
Noticed::Event.where(type: YourNotifierClassName.name) # good
Noticed::Event.where(type: "YourNotifierClassName") # bad
```

When renaming a notification class you will need to backfill existing notifications to reference the new name.

```ruby
Noticed::Event.where(type: "OldNotifierClassName").update_all(type: NewNotifierClassName.name)
Noticed::Notification.where(type: "OldNotifierClassName::Notification").update_all(type: NewNotifierClassName::Notification.name)
```

## 🚛 Delivery Methods

The delivery methods are modular so you can customize the way each type gets delivered.

For example, emails will require a subject, body, and email address while an SMS requires a phone number and simple message. You can define the formats for each of these in your Notifier and the delivery method will handle the processing of it.

### Fallback Notifications

A common pattern is to deliver a notification via the database and then, after some time has passed, email the user if they have not yet read the notification. You can implement this functionality by combining multiple delivery methods, the `delay` option, and the conditional `if` / `unless` option.

```ruby
class CommentNotifier< Noticed::Base
  deliver_by :database
  deliver_by :email, mailer: 'CommentMailer', delay: 15.minutes, unless: :read?
end
```

Here a notification will be created immediately in the database (for display directly in your app). If the notification has not been read after 15 minutes, the email notification will be sent. If the notification has already been read in the app, the email will be skipped.

You can also configure multiple fallback options:

```ruby
class CriticalSystemNotifier < Noticed::Base
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
class MyNotifier < Noticed::Base
  deliver_by :discord, class: "DeliveryMethods::Discord"
end
```

Delivery methods have access to the following methods and attributes:

* `record` - The instance of the Notification. You can call methods on the notification to let the user easily override formatting and other functionality of the delivery method.
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

class CommentNotifier < Noticed::Base
  deliver_by :discord, class: 'DeliveryMethods::Discord'
end
```

Now it will raise an error because a required argument is missing.

To fix the error, the argument has to be passed correctly. For example:

```ruby
class CommentNotifier < Noticed::Base
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

Convert back into a Noticed notifier object:

```ruby
@notification.to_notifier
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
CommentNotifier.with(post: @post).deliver(user)
# Lookup Notifications where params: {post: @post}
@post.notifications_as_post

CommentNotifier.with(parent: @post).deliver(user)
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
