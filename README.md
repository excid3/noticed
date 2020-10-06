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
* Twilio (SMS)
* Vonage / Nexmo (SMS)

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

* `if: :method_name`  - Calls `method_name`and cancels delivery method if `false` is returned
* `unless: :method_name`  - Calls `method_name`and cancels delivery method if `true` is returned

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

## 🚛 Delivery Methods

The delivery methods are designed to be modular so you can customize the way each type gets delivered.

For example, emails will require a subject, body, and email address while an SMS requires a phone number and simple message. You can define the formats for each of these in your Notification and the delivery method will handle the processing of it.

### Database

Writes notification to the database.

`deliver_by :database`

**Note:** Database notifications are special in that they will run before the other delivery methods. We do this so you can reference the database record ID in other delivery methods.

##### Options

* `association` - *Optional*

  The name of the database association to use. Defaults to `:notifications`

* `format: :format_for_database` - *Optional*

  Use a custom method to define the attributes saved to the database

### Email

Sends an email notification. Emails will always be sent with `deliver_later`

`deliver_by :email, mailer: "UserMailer"`

##### Options

* `mailer` - **Required**

  The mailer that should send the email

* `method: :invoice_paid` - *Optional*

  Used to customize the method on the mailer that is called

* `format: :format_for_email` - *Optional*

  Use a custom method to define the params sent to the mailer. `recipient` will be merged into the params.

### ActionCable

Sends a notification to the browser via websockets (ActionCable channel by default).

`deliver_by :action_cable`

##### Options

* `format: :format_for_action_cable` - *Optional*

  Use a custom method to define the Hash sent through ActionCable

* `channel` - *Optional*

  Override the ActionCable channel used to send notifications.

  Defaults to `Noticed::NotificationChannel`

### Slack

Sends a Slack notification via webhook.

`deliver_by :slack`

##### Options

* `format: :format_for_slack` - *Optional*

  Use a custom method to define the payload sent to Slack. Method should return a Hash.

* `url: :url_for_slack` - *Optional*

  Use a custom method to retrieve the Slack Webhook URL. Method should return a String.

  Defaults to `Rails.application.credentials.slack[:notification_url]`

### Twilio SMS

Sends an SMS notification via Twilio.

`deliver_by :twilio`

##### Options

* `credentials: :get_twilio_credentials` - *Optional*

  Use a custom method to retrieve the credentials for Twilio. Method should return a Hash with `:account_sid`, `:auth_token` and `:phone_number` keys.

  Defaults to `Rails.application.credentials.twilio[:account_sid]` and `Rails.application.credentials.twilio[:auth_token]`

* `url: :get_twilio_url` - *Optional*

  Use a custom method to retrieve the Twilio URL.  Method should return the Twilio API url as a string.

  Defaults to `"https://api.twilio.com/2010-04-01/Accounts/#{twilio_credentials(recipient)[:account_sid]}/Messages.json"`

* `format: :format_for_twilio` - *Optional*

  Use a custom method to define the payload sent to Twilio. Method should return a Hash.

  Defaults to:

  ```ruby
  {
    Body: notification.params[:message],
    From: twilio_credentials[:number],
    To: recipient.phone_number
  }
  ```

### Vonage SMS

Sends an SMS notification via Vonage / Nexmo.

`deliver_by :vonage`

##### Options

* `credentials: :get_credentials` - *Optional*

  Use a custom method for retrieving credentials. Method should return a Hash with `:api_key` and `:api_secret` keys.

  Defaults to `Rails.application.credentials.vonage[:api_key]` and `Rails.application.credentials.vonage[:api_secret]`

* `deliver_by :vonage, format: :format_for_vonage` - *Optional*

  Use a custom method to generate the params sent to Vonage. Method should return a Hash. Defaults to:

  ```ruby
  {
    api_key: vonage_credentials[:api_key],
    api_secret: vonage_credentials[:api_secret],
    from: notification.params[:from],
    text: notification.params[:body],
    to: notification.params[:to],
    type: "unicode"
  }
  ```

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

#### Limitations

Rails 6.1+ can serialize Class and Module objects as arguments to ActiveJob. The following syntax should work for Rails 6.1+:

```ruby
  deliver_by DeliveryMethods::Discord
```

For Rails 6.0, you must pass strings of the class names in the `deliver_by` options.

```ruby
  deliver_by :discord, class: "DeliveryMethods::Discord"
```

We recommend the Rails 6.0 compatible options to prevent confusion.

### 📦 Database Model

The Notification database model includes several helpful features to make working with database notifications easier.

#### Class methods

Sorting notifications by newest first:

```ruby
user.notifications.newest_first
```

Marking all notifications as read:

```ruby
user.notifications.mark_as_read!
```

#### Instance methods

Convert back into a Noticed notification object:

```ruby
@notification.to_notification
```

Mark notification as read:

```ruby
@notification.mark_as_read!
```

Check if read / unread:

```ruby
@notification.read?
@notification.unread?
```

#### Associating Notifications

Adding notification associations to your models makes querying and deleting notifications easy and is a pretty critical feature of most applications.

For example, in most cases, you'll want to delete notifications for records that are destroyed.

##### JSON Columns

If you're using MySQL or Postgresql, the `params` column on the notifications table is in `json` or `jsonb` format and can be queried against directly.

For example,  we can query the notifications and delete them on destroy like so:

```ruby
class Post < ApplicationRecord
  def notifications
    # Exact match
    @notifications ||= Notification.where(params: { post: self })

    # Or Postgres syntax to query the post key in the JSON column
    # @notifications ||= Notification.where("params->'post' = ?", Noticed::Coder.dump(self).to_json)
  end

  before_destroy :destroy_notifications

  def destroy_notifications
    notifications.destroy_all
  end
end
```

##### Polymorphic Assocation

If your notification is only associated with one model or you're using a `text` column for your params column , then a polymorphic association is what you'll want to use.

1. Add a polymorphic association to the Notification model. `rails g migration AddNotifiableToNotifications notifiable:belongs_to{polymorphic}`

2. Add `has_many :notifications, as: :notifiable, dependent: :destroy` to each model

3. Customize database `format: ` option to write the `notifiable` attribute(s) when saving the notification

   ```ruby
   class ExampleNotification < Noticed::Base
     deliver_by :database, format: :format_for_database

     def format_for_database
       {
         notifiable: params.delete(:post),
         type: self.class.name,
         params: params
       }
     end
   end
   ```

## 🙏 Contributing

This project uses [Standard](https://github.com/testdouble/standard) for formatting Ruby code. Please make sure to run `standardrb` before submitting pull requests.

## 📝 License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
