### Unreleased

### 2.7.1

* Fix `recipients :symbol` ignored when pointing to a private method

### 2.7.0

* Add lazy load hooks for delivery methods

### 2.6.2

* Fix lazy load hook names

### 2.6.1

* Handle text/html and application/json responses from Slack #531
* Handle 400 errors for FCM deliveries #532
* Add lazy load hooks for models

### 2.6.0

* Add `mark_as_read_and_seen` and `mark_as_unread_and_unseen` class methods to `Noticed::Notification`
* Add support for extra kwargs to `mark_as` class methods on `Noticed::Notification`

### 2.5.1

* Slack delivery methods now verify the `{ok: true/false}` response to catch errors correctly #515

### 2.5.0

* Inherit Notification from parent class Notification.
* Support callbacks in bulk delivery methods.

### 2.4.3

* Add translation and URL helpers to Ephemeral notifiers & notifications #485

### 2.4.2

* The `parent_class` configuration now also changes the parent class for `Noticed::EventJob`. #483
* Include translation support in Ephemeral notifications #484

### 2.4.1

* Include private methods when checking if respond_to?(:method). Fixes #475

### 2.4.0

* Add `recipients` feature to let Notifiers determine their recipients

```ruby
class CommentNotifier < ApplicationNotifier
  # Notify all the commenters on this post except the new comment author

  # Can be given a lambda or Proc
  recipients ->{ params[:comment].post.commenters.excluding(params[:comment].user).distinct }

  # Can be given a block
  recipients do
    params[:comment].post.commenters.excluding(params[:comment].user).distinct
  end

  # Or can call a method
  recipients :fetch_recipients

  def fetch_recipients
    params[:comment].post.commenters.excluding(params[:comment].user).distinct
  end
end
```

### 2.3.3

* Use `public_send` for Email delivery so it doesn't accidentally call private methods.

### 2.3.2

* Set `:json` type on `:params` column with default to better integrate with ActiveRecord.
  This fixes sqlserver (and probably other databases). #451

### 2.3.1

* Skip `ApplicationNotifier` in generator if it already exists

### 2.3.0

* Add `error_handler` to Twilio delivery method #444
* Fix `record` being removed for `Ephemeral` notifications #448

### 2.2.2

* `fetch_constant` will now constantize Strings returned from procs or method calls

### 2.2.1

* `fetch_constant` used by Email and ActionCable delivery methods now support procs and method calls with symbols like other options

### 2.2.0

* Add `config.before_enqueue` callback
  This callback can be used to skip enqueuing delivery methods:

```ruby
class CommentNotifier < Noticed::Event
  deliver_by :email do |config|
    config.before_enqueue = ->{ throw(:abort) unless recipient.email_notifications? }
  end
end
```

* Fix iOS `format` option with Symbols. This now passes the `notification` and `apn` objects instead of just the `apn`.

```ruby
config.format = :ios_format

# ...
def ios_format(notification, apn)
end
```

* Re-add `deserialize_error?` to `Noticed::Event`

### 2.1.3

* Stringify keys for Twilio Messaging json

### 2.1.2

* Fix counter cache migration version for older Rails

### 2.1.1

* Fix duplicate column in migrations.
* Add compatibility for apps that don't use ActionCable.

### 2.1.0

[!IMPORTANT] Run `rails noticed:install:migrations` to upgrade to this version

* Add `notifications_count` counter cache to Noticed::Event.
* Add `has_noticed_notifications` for backwards compatibility.
* Add `Noticed::Ephemeral` notifiers that skip the database records. These use ActiveModel to simulate Notifiers in memory and should work the same as a regular Notifier.

### 2.0.6

* Add `param(s)` and `deliver_later` back with deprecations where necessary to ease upgrading from v1

### 2.0.5

* `mark_as_read` and other class methods will now write `updated_at` as well to bust caches

### 2.0.4

* Validate param key exists, not the value
* Fix recipients that are STI models by storing base class name
* Re-add delivery method callbacks

### 2.0.3

* Notifier generator now ensures the `Notifier` suffix.

```bash
rails g noticed:notifier Example #=> app/notifiers/example_notifier.rb
rails g noticed:notifier ExampleNotifier #=> app/notifiers/example_notifier.rb
```

* Delivery method options set to a Symbol will now pass the `notification` argument when calling the method instead of the delivery method instance.

```ruby
class CommentNotifier
  deliver_by :email do
    config.if = :prefers_email?
  end

  def prefers_email?(notification)
    notification.recipient.preferences[:email]
  end
end
```

### 2.0.2

* Add `Noticed::NotificationChannel` and change defaults for ActionCable deliveries to this channel and stream to `recipient`

### 2.0.1

* Include `notification` and `recipient` in email params. Fixes #366

### 2.0.0

* [Breaking] Noticed now provides its own models for managing notifications. Migrate existing model(s) to use the new Noticed tables.

TODO - add migration example

* [Breaking] Noticed::NotificationChannel has been removed. Use an ActionCable channel in your application instead.
* [Breaking] Twilio has been renamed to `twilio_messaging` to provide support for other Twilio services in the future.
* [Breaking] Vonage / Nexmo has been renamed to `vonage_sms` to provide support for other Vonage services in the future.

```ruby
class NotificationChannel < ApplicationCable::Channel
  def subscribed
    stream_for current_user
  end

  def unsubscribed
    stop_all_streams
  end
end
```

* `Notifications` have now been renamed to `Notifiers` and now inherit from the
* Email delivery method now supports args
* Support html safe translations for Rails 7+

### 1.6.3

* Fix `debug` and `ignore_failure` options in `post` requests. #284 - @mike-burns
* Add `logger` option to delivery methods to allow overriding the logger (defaults to `Rails.logger`) - @excid3

### 1.6.2

* Improve deprecation fix to include Rails 7.1.0.alpha and higher

### 1.6.1

* Fix overridden `Object#method` in `Noticed::DeliveryMethods::Email` - @quadule
* Fix Rails 7.1 deprecation warning #281 - @excid3

### 1.6.0

* Catch deserialization errors. Instead of raising an ActiveRecord::RecordNotFound error, Noticed will replace params with information about the error.
```ruby
{:noticed_error=>"Couldn't find Account with 'id'=100000", :original_params=>{"foo"=>"bar", "account"=>{"_aj_globalid"=>"gid://dummy/Account/100000"}, "_aj_symbol_keys"=>["account"]}}
```
* Add `deserialize_error?` method to Noticed::Model for detecting if a model had issues deserializing params. You can use this method to clean up invalid notifications.

### 1.5.9

* Add dynamic delay option support - @excid3

### 1.5.8

* Check FCM response code correctly - @HeshamMagdy97

### 1.5.7

* Cleanup device token on 404 (Unregistered) error only and raise on all other error codes - @cjilbert504

### 1.5.6

* Add Firebase Cloud Messaging (FCM) delivery method - @cjilbert504 @excid3

### 1.5.5

* Support `File` and `StringIO` objects for iOS `cert_path` - @erbunao

### 1.5.4

* Fix `recipient` assignment - @clinejj

### 1.5.3

* Add symbol support for `development` option for iOS deliveries - @joemasilotti

### 1.5.2

* Rescue from database connection errors when loading Noticed::Model #121 - @adriancb

### 1.5.1

* Fix `record` assignment - @leighhalliday

### 1.5.0

* Add iOS Apple Push Notifications - @excid3 @joemasilotti
* Customizable stream name for ActionCable deliveries - @excid3
* Set recipient when rehydrating notification objects from the database - @RolandStuder
* Support postgis database in model generator - @bmorrall @csutter
* Allow string, symbol, or class for `mailer` option with email delivery - @excid3
* Parameterless notification helpers - @SirRawlins
* Add enqueue option to email delivery method - @coder2000

### 1.4.1

* Fix early db access by moving constant lookup into the method. Fixes the situation of compiling assets needing database access. - @excid3

### 1.4.0

* Add Rails 5.2 support. Backports ActiveJob and ActionCable functionality for compatibility. - @lorint & @excid3

# 1.3.2

* Add `queue` option for delivery methods - @iheanyi

### 1.3.1

* Safely handle choosing coder when database or table doesn't exist - @excid3

### 1.3.0

* Add `has_noticed_notifications` helper for models - @excid3
* Use `json` column for params on SQLite by default instead of text - @excid3
* Add Ruby 3.0 to CI - @excid3

### 1.2.21

* [NEW] Delegate `read?` and `unread?` in notification objects to the database record - @excid3
* [NEW] Always merge `recipient` and `record` into email params - @silva96

### 1.2.20

* [NEW] Add `Notification.mark_as_unread!` class method - @excid3

### 1.2.19

* [FIX] Database delivery can't be delayed, otherwise the database record won't be available for the other deliveries - @rbague

### 1.2.18

* [NEW] Add `delay` option to delay the delivery of a specific delivery method - @rbague

### 1.2.17

* [NEW] Microsoft Teams delivery method - @jordanbrock
* [NEW] Add `mark_as_unread!` instance method for `Notification` model - @pdunleav

### 1.2.16

* [FIX] Ensure `json` is used by MySQL for `params` column in generator - @mikelkew
* [NEW] Update generator to add index for `read_at` column - @mikelkew
* [NEW] Add `option` and `options` for validating Delivery Method options - @rbague

### 1.2.15

* [FIX] Autoload ActionCable channel so Noticed can be used without ActionCable

### 1.2.14

* [FIX] Add `params` so delivery methods can access them without going through `notification`

### 1.2.13

* [NEW] Validate that delivery by emails (`deliver_by :email`) always have a mailer specified
* [NEW] Allow validating options in custom delivery methods
* [FIX] Add `null: false` to `type` column in Notification migration

### 1.2.12

* [NEW] Add `noticed:delivery_method` generator to create custom delivery methods

### 1.2.11

* [FIX] Use ActiveRecord configuration to detect adapter without establishing a database connection

### 1.2.10

* [NEW] Add Noticed::TextCoder for databases without json support
* [NEW] Update generator to make params column json for MySQL, jsonb for Postgres, and text for everything else
* [FIX] Keyword args warning for delivery methods is now fixed

### 1.2.9

* [FIX] Recipient is available in `if` & `else` options

### 1.2.8

* [FIX] Use form data when sending to Twilio

### 1.2.7

* [NEW] Add i18n_scope - @rbague
* [NEW] Add `params` for specifying multiple required params - @rbague
* [NEW] Allow passing in object or string for action_cable channel option - @excid3
* [FIX] Skip JSON parse if deserializing was already done - @excid3

### 1.2.6

* [FIX] Fix Slack default params #13 - @itsderek23

### 1.2.5

* [FIX] Improve serializer to handle text, json, and jsonb columns

### 1.2.4

* Include `record` in email params by default

### 1.2.3

* Adds `recipient` method on notification so they can access it during delivery. Useful when formatting to include recipient details
* Merge `recipient` into params by default when delivering email notifications

### 1.2.2

* [FIX] Remove duplicates when delivering notification to multiple receipients

### 1.2.1

* [NEW] Allow delivering notification to multiple recipients

### 1.2.0

* Translation helpers
* Allow notification objects to call Rails url helpers directly
* Add `noticed:notification` generator
* Allow changing database association name with `deliver_by :database, association: :notifications`
* Add `Noticed::Model` concern for database notifications
* Add notification database model generator

### 1.1.0

* Callbacks for notification around delivery
* Callbacks for delivery methods around delivery


### 1.0.0

* Initial release
