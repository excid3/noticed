# Noticed

## 🎉  Notifications for your Ruby on Rails app.

[![Build Status](https://github.com/excid3/noticed/workflows/Tests/badge.svg)](https://github.com/excid3/noticed/actions) [![Gem Version](https://badge.fury.io/rb/noticed.svg)](https://badge.fury.io/rb/noticed)

> [!IMPORTANT]
> **⚠️ Upgrading from V1? Read the [Upgrade Guide](https://github.com/excid3/noticed/blob/main/UPGRADE.md)!**

Noticed is a gem that allows your application to send notifications of varying types, over various mediums, to various recipients. Be it a Slack notification to your own team when some internal event occurs or a notification to your user, sent as a text message, email, and real-time UI element in the browser, Noticed supports all of the above (at the same time)!

Noticed implements two top-level types of delivery methods:

1. **Individual Deliveries**: Where each recipient gets their own notification
<details>
<summary> Show Example </summary>

Let’s use a car dealership as an example here. When someone purchases a car, a notification will be sent to the buyer with some contract details (“Congrats on your new 2024 XYZ Model...”), another to the car sales-person with different details (“You closed X deal; your commission is Y”), and another to the bank handling the loan with financial details (“New loan issued; amount $20,000...”). The event (the car being sold) necessitates multiple notifications being sent out to different recipients, but each contains its own unique information and should be separate from the others. These are individual deliveries.
</details>

2. **Bulk Deliveries**: One notification for all recipients. This is useful for sending a notification to your Slack team, for example.

<details>
<summary> Show Example </summary>
Let’s continue with the car-sale example here. Consider that your development team created the car-sales application that processed the deal above and sent out the notifications to the three parties. For the sake of team morale and feeling the ‘wins’, you may want to implement a notification that notifies your internal development team whenever a car sells through your platform. In this case, you’ll be notifying many people (your development team, maybe others at your company) but with the same content (“someone just bought a car through our platform!”). This is a bulk delivery. It’s generally a single notification that many people just need to be made aware of.

Bulk deliveries are typically used to push notifications to other platforms where users are managed (Slack, Discord, etc.) instead of your own.
</details>

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

<a href="https://www.youtube.com/watch?v=SzX-aBEqnAc"><img src="https://i.imgur.com/UvVKWwD.png" title="How to add Notifications to Rails with Noticed" width="50%" /></a>

[Watch Screencast](https://www.youtube.com/watch?v=SzX-aBEqnAc)

## 🚀 Installation
Run the following command to add Noticed to your Gemfile:

```ruby
bundle add "noticed"
```

Generate then run the migrations:

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

### Usage Contents
- [Notifier Objects](#notifier-objects)
  - [Delivery Method Configuration](#delivery-method-configuration)
  - [Required Params](#required-params)
  - [Helper Methods](#helper-methods)
  - [URL Helpers](#url-helpers)
  - [Translations](#translations)
  - [Tip: Capture User Preferences](#tip-capture-user-preferences)
  - [Tip: Extracting Delivery Method Configurations](#tip-extracting-delivery-method-configurations)
  - [Shared Delivery Method Options](#shared-delivery-method-options)
- [Sending Notifications](#sending-notifications)
- [Custom Noticed Model Methods](#custom-noticed-model-methods)

### Notifier Objects

Notifiers are essentially the controllers of the Noticed ecosystem and represent an Event. As such, we recommend naming them with the event they model in mind — be it a `NewSaleNotifier,` `ChargeFailureNotifier`, etc.

Notifiers must inherit from `Noticed::Event`. This provides all of their functionality.

A Notifier exists to declare the various delivery methods that should be used for that event _and_ any notification helper methods necessary in those delivery mechanisms. In this example we’ll deliver by `:action_cable` to provide real-time UI updates to users’ browsers, `:email` if they’ve opted into email notifications, and a bulk notification to `:discord` to tell everyone on the Discord server there’s been a new comment.

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
        message: message,
        channel: :general
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

#### Delivery Method Configuration

Each delivery method can be configured with a block that yields a `config` object.

Procs/Lambdas will be evaluated when needed and symbols can be used to call a method.

When a lambda is passed, it will not pass any arguments and evaluates the Proc in the context of the Noticed::Notification

If you are using a symbol to call a method, we pass the notification object as an argument to the method. This allows you to access the notification object within the method.
Your method must accept a single argument. If you don't need to use the object you can just use `(*)`.

<details>
<summary> Show Example </summary>

```ruby
class CommentNotifier < Noticed::Event
  deliver_by :ios do |config|
    config.format = :ios_format
    config.apns_key = :ios_cert
    config.key_id = :ios_key_id
    config.team_id = :ios_team_id
    config.bundle_identifier = Rails.application.credentials.dig(:ios, :bundle_identifier)
    config.device_tokens = :ios_device_tokens
    config.if = -> { recipient.send_ios_notification? }
  end

  def ios_format(apn)
    apn.alert = { title:, body: }
    apn.mutable_content = true
    apn.content_available = true
    apn.sound = "notification.m4r"
    apn.custom_payload = {
      url:,
      type: self.class.name,
      id: record.id,
      image_url: "" || image_url,
      params: params.to_json
    }
  end

  def ios_cert(*)
    Rails.application.credentials.dig(:ios, Rails.env.to_sym, :apns_token_cert)
  end

  def ios_key_id(*)
    Rails.application.credentials.dig(:ios, Rails.env.to_sym, :key_id)
  end

  def ios_team_id(*)
    Rails.application.credentials.dig(:ios, Rails.env.to_sym, :team_id)
  end

  def ios_bundle_id(*)
    Rails.application.credentials.dig(:ios, Rails.env.to_sym, :bundle_identifier)
  end

  def ios_device_tokens(notification)
    notification.recipient.ios_device_tokens
  end

  def url
    comment_thread_path(record.thread)
  end
end

class Recipent < ApplicationRecord # or whatever your recipient model is
  has_many :ios_device_tokens

    def send_ios_notification?
        # some logic
    end
end
```
</details>

More examples are in the docs for each delivery method.

#### Required Params

While explicit / required parameters are completely optional, Notifiers are able to opt in to required parameters via the `required_params` method:

```ruby
class CarSaleNotifier < Noticed::Event
  deliver_by :email { |c| c.mailer = "BranchMailer" }

  # `record` is the Car record, `Branch` is the dealership
  required_params :branch

  # To validate the `:record` param, add a validation since it is an association on the Noticed::Event
  validates :record, presence: true
end
```

Which will validate upon any invocation that the specified parameters are present:

```ruby
CarSaleNotifier.with(record: Car.last).deliver(Branch.last)
#=> Noticed::ValidationError("Param `branch` is required for CarSaleNotifier")

CarSaleNotifier.with(record: Car.last, branch: Branch.last).deliver(Branch.hq)
#=> OK
```

#### Helper Methods

Notifiers can implement various helper methods, within a `notification_methods` block, that make it easier to render the resulting notification directly. These helpers can be helpful depending on where and how you choose to render notifications. A common use is rendering a user’s notifications in your web UI as standard ERB. These notification helper methods make that rendering much simpler:

```erb
<div>
  <% @user.notifications.each do |notification| %>
    <%= link_to notification.message, notification.url %>
  <% end %>
</div>
```

On the other hand, if you’re using email delivery, ActionMailer has its own full stack for setting up objects and rendering. Your notification helper methods will always be available from the notification object, but using ActionMailer’s own paradigms may fit better for that particular delivery method. YMMV.

#### URL Helpers

Rails url helpers are included in Notifiers by default so you have full access to them in your notification helper methods, just like you would in your controllers and views.

_But don't forget_, you'll need to configure `default_url_options` in order for Rails to know what host and port to use when generating URLs.

```ruby
Rails.application.routes.default_url_options[:host] = 'localhost:3000'
```

#### Translations

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

#### Tip: Capture User Preferences

You can use the `if:` and `unless: ` options on your delivery methods to check the user's preferences and skip processing if they have disabled that type of notification.

For example:

```ruby
class CommentNotifier < Noticed::Event
  deliver_by :email do |config|
    config.mailer = 'CommentMailer'
    config.method = :new_comment
    config.if = ->{ recipient.email_notifications? }
  end
end
```
#### Tip: Extracting Delivery Method Configurations

If you want to reuse delivery method configurations across multiple Notifiers, you can extract them into a module and include them in your Notifiers.

```ruby
# /app/notifiers/notifiers/comment_notifier.rb
class CommentNotifier < Noticed::Event
  include IosNotifier
  include AndriodNotifer
  include EmailNotifier

  validates :record, presence: true
end

# /app/notifiers/concerns/ios_notifier.rb
module IosNotifier
  extend ActiveSupport::Concern

  included do
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
      config.if = -> { recipient.ios_notifications? }
    end
  end
end
```

#### Shared Delivery Method Options

Each of these options are available for every delivery method (individual or bulk). The value passed may be a lambda, a symbol that represents a callable method, a symbol value, or a string value.

* `config.if` — Intended for a lambda or method; runs after the `wait` if configured; cancels the delivery method if returns falsey
* `config.unless`  — Intended for a lambda or method; runs after the `wait` if configured; cancels the delivery method if returns truthy
* `config.wait` — (Should yield an `ActiveSupport::Duration`) Delays the job that runs this delivery method for the given duration of time
* `config.wait_until` — (Should yield a specific time object) Delays the job that runs this delivery method until the specific time specified
* `config.queue` — Sets the ActiveJob queue name to be used for the job that runs this delivery method

### 📨 Sending Notifications

Following the `NewCommentNotifier` example above, here’s how we might invoke the Notifier to send notifications to every author in the thread about a new comment being added:

```ruby
NewCommentNotifier.with(record: @comment, foo: "bar").deliver(@comment.thread.all_authors)
```

This instantiates a new `NewCommentNotifier` with params (similar to ActiveJob, any serializable params are permitted), then delivers notifications to all authors in the thread.

✨ The `record:` param is a special param that gets assigned to the `record` polymorphic association in the database. You should try to set the `record:` param where possible. This may be best understood as ‘the record/object this notification is _about_’, and allows for future queries from the record-side: “give me all notifications that were generated from this comment”.

This invocation will create a single `Noticed::Event` record and a `Noticed::Notification` record for each recipient. A background job will then process the Event and fire off a separate background job for each bulk delivery method _and_ each recipient + individual-delivery-method combination. In this case, that’d be the following jobs kicked off from this event:

- A bulk delivery job for `:discord` bulk delivery
- An individual delivery job for `:action_cable` method to the first thread author
- An individual delivery job for `:email` method to the first thread author
- An individual delivery job for `:action_cable` method to the second thread author
- An individual delivery job for `:email` method to the second thread author
- Etc...

### Custom Noticed Model Methods

In order to extend the Noticed models you'll need to use a concern and a to_prepare block:

```ruby
# config/initializers/noticed.rb
module NotificationExtensions
  extend ActiveSupport::Concern

  included do
    belongs_to :organization

    scope :filter_by_type, ->(type) { where(type:) }
    scope :exclude_type, ->(type) { where.not(type:) }
  end

  # You can also add instance methods here
end

Rails.application.config.to_prepare do
  # You can extend Noticed::Event or Noticed::Notification here
  Noticed::Event.include EventExtensions
  Noticed::Notification.include NotificationExtensions
end
```

The `NotificationExtensions` class could be separated into it's own file and live somewhere like `app/models/concerns/notification_extensions.rb`.

If you do this, the `to_prepare` block will need to be in `application.rb` instead of an initializer.

```ruby
# config/application.rb
module MyApp
  class Application < Rails::Application

    # ...

    config.to_prepare do
      Noticed::Event.include Noticed::EventExtensions
      Noticed::Notification.include Noticed::NotificationExtensions
    end
  end
end
```

## ✅ Best Practices

### Renaming Notifiers

If you rename a Notifier class your existing data and Noticed setup may break. This is because Noticed serializes the class name and sets it to the `type` column on the `Noticed::Event` record and the `type` column on the `Noticed::Notification` record.

When renaming a Notifier class you will need to backfill existing Events and Notifications to reference the new name.

```ruby
Noticed::Event.where(type: "OldNotifierClassName").update_all(type: NewNotifierClassName.name)
# and
Noticed::Notification.where(type: "OldNotifierClassName::Notification").update_all(type: "#{NewNotifierClassName.name}::Notification")
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

### No Delivery Methods

It’s worth pointing out that you can have a fully-functional and useful Notifier that has _no_ delivery methods. This means that invoking the Notifier and ‘sending’ the notification will only create new database records (no external surfaces like email, sms, etc.). This is still useful as it’s the database records that allow your app to render a user’s (or other object’s) notifications in your web UI.

So even with no delivery methods set, this example is still perfectly available and helpful:

```erb
<div>
  <% @user.notifications.each do |notification| %>
    <%= link_to notification.message, notification.url %>
  <% end %>
</div>
```

Sending a notification is entirely an internal-to-your-app function. Delivery methods just get the word out! But many apps may be fully satisfied without that extra layer.

### Fallback Notifications

A common pattern is to deliver a notification via a real (or real-ish)-time service, then, after some time has passed, email the user if they have not yet read the notification. You can implement this functionality by combining multiple delivery methods, the `wait` option, and the conditional `if` / `unless` option.

```ruby
class NewCommentNotifier< Noticed::Event
  deliver_by :action_cable
  deliver_by :email do |config|
    config.mailer = "CommentMailer"
    config.wait = 15.minutes
    config.unless = -> { read? }
  end
end
```

Here a notification will be created immediately in the database (for display directly in your app’s web interface) and sent via ActionCable. If the notification has not been marked `read` after 15 minutes, the email notification will be sent. If the notification has already been read in the app, the email will be skipped.

_A note here: notifications expose a `#mark_as_read` method, but your app must choose when and where to call that method._

You can mix and match the options and delivery methods to suit your application specific needs.

### 🚚 Custom Delivery Methods

If you want to build your own delivery method to deliver notifications to a specific service or medium that Noticed doesn’t (or doesn’t _yet_) support, you’re welcome to do so! To generate a custom delivery method, simply run

`rails generate noticed:delivery_method Discord`

This will generate a new `DeliveryMethods::Discord` class inside the `app/notifiers/delivery_methods` folder, which can be used to deliver notifications to Discord.

```ruby
class DeliveryMethods::Discord < ApplicationDeliveryMethod
  # Specify the config options your delivery method requires in its config block
  required_options # :foo, :bar

  def deliver
    # Logic for sending the notification
  end
end

```

You can use the custom delivery method thus created by adding a `deliver_by` line with a unique name and `class` option in your notification class.

```ruby
class MyNotifier < Noticed::Event
  deliver_by :discord, class: "DeliveryMethods::Discord"
end
```

<details>
<summary>Turbo Stream Custom Delivery Method Example</summary>

A common custom delivery method in the Rails world might be to Delivery to the web via turbo stream.

Note: This example users custom methods that extend the `Noticed::Notification` class.

See the [Custom Noticed Model Methods](#custom-noticed-model-methods) section for more information.

```ruby
# app/notifiers/delivery_methods/turbo_stream.rb
class DeliveryMethods::TurboStream < ApplicationDeliveryMethod
  def deliver
    return unless recipient.is_a?(User)

    notification.broadcast_update_to_bell
    notification.broadcast_replace_to_index_count
    notification.broadcast_prepend_to_index_list
  end
end
```

```ruby
# app/models/concerns/noticed/notification_extensions.rb
module Noticed::NotificationExtensions
  extend ActiveSupport::Concern

  def broadcast_update_to_bell
    broadcast_update_to(
      "notifications_#{recipient.id}",
      target: "notification_bell",
      partial: "navbar/notifications/bell",
      locals: { user: recipient }
    )
  end

  def broadcast_replace_to_index_count
    broadcast_replace_to(
      "notifications_index_#{recipient.id}",
      target: "notification_index_count",
      partial: "notifications/notifications_count",
      locals: { count: recipient.reload.notifications_count, unread: recipient.reload.unread_notifications_count }
    )
  end

  def broadcast_prepend_to_index_list
    broadcast_prepend_to(
      "notifications_index_list_#{recipient.id}",
      target: "notifications",
      partial: "notifications/notification",
      locals: { notification: self }
    )
  end
end
```
</details>

Delivery methods have access to the following methods and attributes:

* `event` — The `Noticed::Event` record that spawned the notification object currently being delivered
* `record` — The object originally passed into the Notifier as the `record:` param (see the ✨ note above)
* `notification` — The `Noticed::Notification` instance being delivered. All notification helper methods are available on this object
* `recipient` — The individual recipient object being delivered to for this notification (remember that each recipient gets their own instance of the Delivery Method `#deliver`)
* `config` — The hash of configuration options declared by the Notifier that generated this notification and delivery
* `params` — The parameters given to the Notifier in the invocation (via `.with()`)

#### Validating config options passed to Custom Delivery methods

The presence of delivery method config options are automatically validated when declaring them with the `required_options` method. In the following example, Noticed will ensure that any Notifier using `deliver_by :email` will specify the `mailer` and `method` config keys:

```ruby
class DeliveryMethods::Email < Noticed::DeliveryMethod
  required_options :mailer, :method

  def deliver
    # ...
    method = config.method
  end
end
```

If you’d like your config options to support dynamic resolution (set `config.foo` to a lambda or symbol of a method name etc.), you can use `evaluate_option`:

```ruby
class NewSaleNotifier < Noticed::Event
  deliver_by :whats_app do |config|
    config.day = -> { is_tuesday? "Tuesday" : "Not Tuesday" }
  end
end

class DeliveryMethods::WhatsApp < Noticed::DeliveryMethod
  required_options :day

  def deliver
    # ...
		config.day #=> #<Proc:0x000f7c8 (lambda)>
    evaluate_option(config.day) #=> "Tuesday"
  end
end
```

#### Callbacks

Callbacks for delivery methods wrap the _actual_ delivery of the notification. You can use `before_deliver`, `around_deliver` and `after_deliver` in your custom delivery methods.

```ruby
class DeliveryMethods::Discord < Noticed::DeliveryMethod
  after_deliver do
    # Do whatever you want
  end
end
```

## 📦 Database Model

The Noticed database models include several helpful features to make working with notifications easier.

### Notification

#### Class methods/scopes

(Assuming your user `has_many :notifications, as: :recipient, class_name: "Noticed::Notification"`)

Sorting notifications by newest first:

```ruby
@user.notifications.newest_first
```

Query for read or unread notifications:

```ruby
user.notifications.read
user.notifications.unread
```

Marking all notifications as read or unread:

```ruby
user.notifications.mark_as_read
user.notifications.mark_as_unread
```

#### Instance methods

Convert back into a Noticed notifier object:

```ruby
@notification.to_notifier
```

Mark notification as read / unread:

```ruby
@notification.mark_as_read
@notification.mark_as_read!
@notification.mark_as_unread
@notification.mark_as_unread!
```

Check if read / unread:

```ruby
@notification.read?
@notification.unread?
```

#### Associating Notifications

Adding notification associations to your models makes querying, rendering, and managing notifications easy (and is a pretty critical feature of most applications).

There are two ways to associate your models to notifications:

1. Where your object `has_many` notifications as the recipient (who you sent the notification to)
2. Where your object `has_many` notifications as the `record` (what the notifications were about)

In the former, we’ll use a `has_many` to `:notifications`. In the latter, we’ll actually `has_many` to `:events`, since `record`s generate notifiable _events_ (and events generate notifications).

We can illustrate that in the following:

```ruby
class User < ApplicationRecord
  has_many :notifications, as: :recipient, dependent: :destroy, class_name: "Noticed::Notification"
end

# All of the notifications the user has been sent
# @user.notifications.each { |n| render(n) }

class Post < ApplicationRecord
  has_many :noticed_events, as: :record, dependent: :destroy, class_name: "Noticed::Event"
  has_many :notifications, through: :noticed_events, class_name: "Noticed::Notification"
end

# All of the notification events this post generated
# @post.notifications
```

#### ActiveJob Parent Class

Noticed uses its own `Noticed::ApplicationJob` as the base job for all notifications.  In the event that you would like to customize the parent job class, there is a `parent_class` attribute that can be overridden with your own class.  This should be done in a `noticed.rb` initializer.

```ruby
Noticed.parent_class = "ApplicationJob"
```

#### Handling Deleted Records

Generally we recommend using a `dependent: ___` relationship on your models to avoid cases where Noticed Events or Notifications are left lingering when your models are destroyed. In the case that they are or data becomes mis-matched, you’ll likely run into deserialization issues. That may be globally alleviated with the following snippet, but use with caution.

```ruby
class ApplicationJob < ActiveJob::Base
  discard_on ActiveJob::DeserializationError
end
```

### Customizing the Database Models

You can modify the database models by editing the generated migrations.

One common adjustment is to change the IDs to UUIDs (if you're using UUIDs in your app).

You can also add additional columns to the `Noticed::Event` and `Noticed::Notification` models.

```ruby
# This migration comes from noticed (originally 20231215190233)
class CreateNoticedTables < ActiveRecord::Migration[7.1]
  def change
    create_table :noticed_events, id: :uuid do |t|
      t.string :type
      t.belongs_to :record, polymorphic: true, type: :uuid
      t.jsonb :params

      # Custom Fields
      t.string :organization_id, type: :uuid, as: "((params ->> 'organization_id')::uuid)", stored: true
      t.virtual :action_type, type: :string, as: "((params ->> 'action_type'))", stored: true
      t.virtual :url, type: :string, as: "((params ->> 'url'))", stored: true

      t.timestamps
    end

    create_table :noticed_notifications, id: :uuid do |t|
      t.string :type
      t.belongs_to :event, null: false, type: :uuid
      t.belongs_to :recipient, polymorphic: true, null: false, type: :uuid
      t.datetime :read_at
      t.datetime :seen_at

      t.timestamps
    end

    add_index :noticed_notifications, :read_at
  end
end
```

The custom fields in the above example are stored as virtual columns.  These are populated from values passed in the `params` hash when creating the notifier.

## 🙏 Contributing

This project uses [Standard](https://github.com/testdouble/standard) for formatting Ruby code. Please make sure to run `standardrb` before submitting pull requests.

Running tests against multiple databases locally:

```
DATABASE_URL=sqlite3:noticed_test rails test
DATABASE_URL=trilogy://root:@127.0.0.1/noticed_test rails test
DATABASE_URL=postgres://127.0.0.1/noticed_test rails test
```

## 📝 License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
