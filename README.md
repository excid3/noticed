# Noticed


### 🎉  Notifications for your Ruby on Rails app.

[![Build Status](https://github.com/excid3/noticed/workflows/Tests/badge.svg)](https://github.com/excid3/noticed/actions) [![Gem Version](https://badge.fury.io/rb/noticed.svg)](https://badge.fury.io/rb/noticed)

Noticed is a gem that allows your application to send notifications of varying types, over various mediums, to various recipients. Be it a Slack notification to your own team when some internal event occurs or a notification to your user, sent as a text message, email, and real-time UI element in the browser, Noticed supports all of the above (at the same time)!

Noticed implements two top-level types of delivery methods:

1. Individual Deliveries: Where each recipient gets their own notification

Let’s use a car dealership as an example here. When someone purchases a car, a notification will be sent to the buyer with some contract details (“Congrats on your new 2024 XYZ Model...”), another to the car sales-person with different details (“You closed X deal; your commission is Y”), and another to the bank handling the loan with financial details (“New loan issued; amount $20,000...”). The event (the car being sold) necessitates multiple notifications being sent out to different recipients, but each contains its own unique information and should be separate from the others. These are individual deliveries.

2. Bulk Deliveries - one notification for all recipients. This is useful for sending a notification to your Slack team, for example.

Let’s continue with the car-sale example here. Consider that your development team created the car-sales application that processed the deal above and sent out the notifications to the three parties. For the sake of team morale and feeling the ‘wins’, you may want to implement a notification that notifies your internal development team whenever a car sells through your platform. In this case, you’ll be notifying many people (your development team, maybe others at your company) but with the same content (“someone just bought a car through our platform!”). This is a bulk delivery. It’s generally a single notification that many people just need to be made aware of.

Bulk deliveries are typically used to push notifications to other platforms where users are managed (Slack, Discord, etc.) instead of your own.

Delivery methods we officially support:

* [ActionCable](docs/delivery_methods/action_cable.md)
* [Apple Push Notification Service](docs/delivery_methods/ios.md)
* [Email](docs/delivery_methods/email.md)
* [Firebase Cloud Messaging](docs/delivery_methods/fcm.md) (iOS, Android, and web clients)
* [Microsoft Teams](docs/delivery_methods/microsoft_teams.md)
* [Slack](docs/delivery_methods/slack.md)
* [Twilio Messaging](docs/delivery_methods/twilio_messaging.md) - SMS, Whatsapp
* [Vonage SMS](docs/delivery_methods/vonage_sms.md)
* [Test](docs/delivery_methods/test.md)

Bulk delivery methods we support:

* [Discord](docs/bulk_delivery_methods/discord.md)
* [Slack](docs/bulk_delivery_methods/slack.md)
* [Webhook](docs/bulk_delivery_methods/webhook.md)

## 🎬 Screencast

<a href="https://www.youtube.com/watch?v=Scffi4otlFc"><img src="https://i.imgur.com/UvVKWwD.png" title="How to add Notifications to Rails with Noticed" width="50%" /></a>

[Watch Screencast](https://www.youtube.com/watch?v=Scffi4otlFc)

## 🚀 Installation
Run the following command to add Noticed to your Gemfile

```ruby
bundle add "noticed"
```

Add the migraitons

```bash
rails noticed:install:migrations
rails db:migrate
```

## 📝 Usage

Noticed operates with a few constructs: Notifiers, delivery methods, and Notification records.

To start, generate a Notifier: 

```sh
rails generate noticed:notifier NewCommentNotifier
```

#### Notifier Objects

Notifiers are essentially the controllers of the Noticed ecosystem and represent an Event. As such, we recommend naming them with the event they model in mind — be it a `NewSaleNotifier,` `ChargeFailureNotifier`, etc.

Notifiers must inherit from `Noticed::Event`. This provides all their functionality and allows them to be delivered.

A Notifier exists to declare the various delivery systems intended to be used for that event _and_ any notification helper methods necessary in those delivery mechanisms. In this example we’ll deliver by `:action_cable` to provide real-time UI updates to users’ browsers, `:email` if they’ve opted into email notifications, and a bulk notification to `:discord` to tell folks on the Discord server there’s been a new comment.

```ruby
# ~/app/notifiers/new_comment_notifier.rb

class NewCommentNotifier < Noticed::Event
  deliver_by :action_cable do |config|
    config.channel = "NotificationsChannel"
    config.stream = :some_stream
  end

  deliver_by :email do |config|
    config.mailer = "CommentMailer"
		config.if = ->(recipient) { !!recipient.preferences[:email] }
  end

  bulk_deliver_by :discord do |config|
    config.url = "https://discord.com/xyz/xyz/123"
    config.json = -> {
      {
        message: message
      }
    }
  end

  notification_methods do
    # I18n helpers
    def message
      t(".message")
    end

    # URL helpers are accessible in notifications
    # Don't forget to set your default_url_options so Rails knows how to generate urls
    def url
      user_post_path(recipient, params[:post])
    end
  end
end
```

For deeper specifics on setting up the `:action_cable`, `:email`, and `:discord` (bulk) delivery methods, refer to their docs: [`action_cable`](docs/delivery_methods/action_cable.md), [`email`](docs/delivery_methods/email.md), and [`discord` (bulk)](docs/bulk_delivery_methods/discord.md).

##### Helper Methods

Notifiers can implement various helper methods, within a `notification_methods` block, that make it easier to render the resulting notification directly. While delivering by email (which has its own ActionMailer stack for rendering and processing) may or may not need these helpers, for example, rendering a notification in a web-view with ERB presents a case where these helpers are useful.

```erb
<div>
  <% @user.notifications.each do |notification| %>
    <%= link_to notification.message, notification.url %>
  <% end %>
</div>
```

##### URL Helpers

Rails url helpers are included in Notifiers by default so you have full access to them in your notification helper methods, just like you would in your controllers and views.

_But don't forget_, you'll need to configure `default_url_options` in order for Rails to know what host and port to use when generating URLs.

```ruby
Rails.application.routes.default_url_options[:host] = 'localhost:3000'
```

##### Translations

We've also included Rails’ `translate` and `t` helpers for you to use in your notification helper methods. This also provides an easy way of scoping translations. If the key starts with a period, it will automatically scope the key under `notifiers`, the underscored name of the notifier class, and `notification`. For example:

From the above Notifier...

```ruby
class NewCommentNotifier < Noticed::Event
  # ...
  
  notification_methods do
    def message
      t(".message")
    end
  end
  
  # ...
end
```

Calling the `message` helper in an ERB view:

```erb
<%= @user.notifications.last.message %>
```

Will look for the following translation path:

```yml
# ~/config/locales/en.yml

en:
  notifiers:
  	new_comment_notifier:
  	  notification:
        message: "Someone posted a new comment!"
```

Or, if you have your Notifier within another module, such as `Admin::NewCommentNotifier`, the resulting lookup path will be `en.notifiers.admin.new_comment_notifier.notification.message` (modules become nesting steps).

##### Tip: Capture User Preferences

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

**Shared Delivery Method Options**

Each of these options are available for every delivery method (individual or bulk). The value passed may be a lambda, a symbol that represents a callable method, a symbol value, or a string value.

* `config.if` — Intended for a lambda or method; runs after the `wait` if configured; cancels the delivery method if returns falsey
* `config.unless`  — Intended for a lambda or method; runs after the `wait` if configured; cancels the delivery method if returns truthy
* `config.wait` — (Should yield an `ActiveSupport::Duration`) Delays the job that runs this delivery method for the given duration of time
* `config.wait_until` — (Should yield a specific time object) Delays the job that runs this delivery method until the specific time specified
* `config.queue` — Sets the ActiveJob queue name to be used for the job that runs this delivery method

#### Sending Notifications

Following the `NewCommentNotifier` example above, here’s how we might invoke the Notifier to send notifications to every author in the thread about a new comment being added:

```ruby
NewCommentNotifier.with(record: @comment, foo: "bar").deliver(@comment.thread.all_authors)
```

This instantiates a new `NewCommentNotifier` with params (similar to ActiveJob, any serializable params are permitted), then delivers notifications to all authors in the thread.

The `record:` param is a special param that gets assigned to the `record` polymorphic association in the database. You should try to set the `record:` param where possible. This may be best understood as ‘the record/object this notification is _about_’.

This invocation will create a single `Noticed::Event` record and a `Noticed::Notification` record for each recipient. A background job will then process the Event and fire off a separate background job for each bulk delivery method and recipient + individual-delivery-method combination. In this case, that’d be the following jobs kicked off from this event:

- A bulk delivery job for `:discord`
- An individual delivery job of `:action_cable` for the first thread author
- An individual delivery job of `:email` for the first thread author
- An individual delivery job of `:action_cable` for the second thread author
- An individual delivery job of `:email` for the second thread author
- Etc...

## ✅ Best Practices

### Renaming Notifiers

If you rename a Notifier class your existing data and Noticed setup can break. This is because Noticed serializes the class name and sets it to the `type` column on the `Noticed::Event` record.

When renaming a Notifier class you will need to backfill existing Events to reference the new name.

```ruby
Noticed::Event.where(type: "OldNotifierClassName").update_all(type: NewNotifierClassName.name)
```

## 🚛 Delivery Methods

The delivery methods are designed to be modular so you can customize the way each type gets delivered.

For example, emails will require a subject, body, and email address while an SMS requires a phone number and simple message. You can define the formats for each of these in your Notifier and the delivery method will handle the processing of it.

Individual delivery methods:

* [ActionCable](docs/delivery_methods/action_cable.md)
* [Apple Push Notification Service](docs/delivery_methods/ios.md)
* [Email](docs/delivery_methods/email.md)
* [Firebase Cloud Messaging](docs/delivery_methods/fcm.md) (iOS, Android, and web clients)
* [Microsoft Teams](docs/delivery_methods/microsoft_teams.md)
* [Slack](docs/delivery_methods/slack.md)
* [Twilio Messaging](docs/delivery_methods/twilio_messaging.md) - SMS, Whatsapp
* [Vonage SMS](docs/delivery_methods/vonage_sms.md)
* [Test](docs/delivery_methods/test.md)

Bulk delivery methods:

* [Discord](docs/bulk_delivery_methods/discord.md)
* [Slack](docs/bulk_delivery_methods/slack.md)
* [Webhook](docs/bulk_delivery_methods/webhook.md)

### Fallback Notifications

A common pattern is to deliver a notification via a real (or real-ish)-time service, then, after some time has passed, email the user if they have not yet read the notification. You can implement this functionality by combining multiple delivery methods, the `wait` option, and the conditional `if` / `unless` option.

```ruby
class NewCommentNotifier< Noticed::Base
  deliver_by :action_cable
  deliver_by :email do |config|
    config.mailer = "CommentMailer"
    config.wait = 15.minutes
    config.unless = -> { read? }
  end
end
```

Here a notification will be created immediately in the database (for display directly in your app’s web interface) and sent via ActionCable. If the notification has not been marked `read` after 15 minutes, the email notification will be sent. If the notification has already been read in the app, the email will be skipped.

You can mix and match the options and delivery methods to suit your application specific needs.

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
