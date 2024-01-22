# Noticed Upgrade Guide

Follow this guide to upgrade your Noticed implementation to the next version

## Noticed 2.0

We've made some major changes to Noticed to simplify and support more delivery methods.

### Models

Instead of having models live in your application, Noticed v2 adds models managed by the gem.

Delete the `Notification` model at `app/models/notification.rb`.

Then run the new migrations:
```bash
rails noticed:install:migrations
rails db:migrate
```

To migrate your data to the new tables, loop through your existing notifications and create new records for each one. You can do this in a Rake task or in the Rails console:

```ruby
# Temporarily define the Notification model to access the old table
class Notification < ActiveRecord::Base
  self.inheritance_column = nil
end

# Migrate each record to the new tables
Notification.find_each do |notification|
  attributes = notification.attributes.slice("type").with_indifferent_access
  attributes[:type] = attributes[:type].sub("Notification", "Notifier")
  attributes[:params] = Noticed::Coder.load(notification.params)
  attributes[:params] = {} if attributes[:params].try(:has_key?, "noticed_error") # Skip invalid records
  attributes[:notifications_attributes] = [{
    type: "#{attributes[:type]}::Notification",
    recipient_type: notification.recipient_type,
    recipient_id: notification.recipient_id,
    read_at: notification.read_at,
    seen_at: notification.read_at
  }]
  Noticed::Event.create!(attributes)
end
```

After migrating, you can drop the old notifications table.

### Parent Class

`Noticed::Base` has been deprecated in favor of `Noticed::Event`. This is an STI model that tracks all Notifier deliveries and recipients.

```ruby
class CommentNotifier < Noticed::Event
end
```

### Database Delivery Method

The database delivery is now baked into notifications.

You will need to remove `deliver_by :database` from your notifiers.

### Notifiers

For clarity, we've renamed `app/notifications` to `app/notifiers`.

**Notifiers** - the class that delivers notifications <br>
**Notification** - the database record of the notification

We recommend renaming your existing classes to match. You'll also need to update the `type` column on existing notifications when renaming.

```ruby
Noticed::Notification.find_each do |notification|
  notification.update(type: notification.type.sub("Notification", "Notifier"))
end
```

### Delivery Method Configuration

Configuration for each delivery method can be contained within a block now. This improves organization for delivery method options by defining them in the block.
Procs/Lambdas will be evaluated when needed and symbols can be used to call a method.

```ruby
class CommentNotifier < Noticed::Event
  deliver_by :action_cable do |config|
    config.channel = "NotificationChannel"
    config.stream = ->{ recipient }
    config.message = :to_websocket
  end

  def to_websocket
    { foo: :bar }
  end
```

### Required Params

`param` and `params` have been renamed to `required_param(s)` to be more clear.

```ruby
class CommentNotifier < Noticed::Event
  required_param :comment
  required_params :account, :comment
end
```

### Helper methods

Helper methods defined in Notifiers have changed slightly. In order to access helper methods from Notification objects, for example:

```erb
<div>
  <% @user.notifications.each do |notification| %>
    <%= link_to notification.message, notification.url %>
  <% end %>
</div>
```

You’ll need to wrap helper methods in the new `notification_methods` block within your Notifier:

```ruby
class NewCommentNotifier < Noticed::Event
  deliver_by :email do |config|
    # ...
  end

  notification_methods do
    # I18n helpers still available here
    def message
      t(".message")
    end

    # URL helpers are available here too
    def url
      user_post_path(recipient, params[:post])
    end
  end
end
```

#### Notification Model Methods

In order to extend the Notification model you'll need to use a concern an a to_prepare block:

```ruby
module NotificationExtensions
  extend ActiveSupport::Concern

  included do
    scope :filter_by_type, ->(type) { where(type:) }
    scope :filter_by_org, ->(organisation_id) { where(organisation_id:) }
    scope :exclude_type, ->(type) { where.not(type:) }

    counter_culture :recipient, column_name: "notifications_count"
    counter_culture :recipient, column_name: proc { |a| 'unread_notifications_count' if a.read_at.nil? },
                              column_names: { Notification.unread => :unread_notifications_count }
  end

  def organisation
    Organisation.find_by(id: organisation_id)
  end
end

Rails.application.config.to_prepare do
  Noticed::Notification.include NotificationExtensions
end
```

### Has Noticed Notifications

`has_noticed_notifications` has been removed in favor of the `record` polymorphic relationship that can be directly queried with ActiveRecord. You can add the necessary json query to your model(s) to restore the json query if needed.

We recommend backfilling the `record` association if your notification params has a primary related record and switching to a has_many association instead.

```ruby
class Comment < ApplicationRecord
  has_many :noticed_events, as: :record, dependent: :destroy, class_name: "Noticed::Event"
end
```

If you would like to keep the JSON querying, you can implement a method for querying your model depending on the database you use:

```ruby
# Define the
param_name = "user"

# PostgreSQL
model.where("params @> ?", Noticed::Coder.dump(param_name.to_sym => self).to_json)

# MySQL
model.where("JSON_CONTAINS(params, ?)", Noticed::Coder.dump(param_name.to_sym => self).to_json)

# SQLite
model.where("json_extract(params, ?) = ?", "$.#{param_name}", Noticed::Coder.dump(self).to_json)

# Other
model.where(params: {param_name.to_sym => self})
```

### Receipient Notifications Association

Recipients can be associated with notifications using the following. This is useful for displaying notifications in your UI.

```ruby
class User < ApplicationRecord
  has_many :notifications, as: :recipient, dependent: :destroy, class_name: "Noticed::Notification"
end
```

### Delivery Method Changes

Options for delivery methods have been renamed for clarity and consistency.

#### ActionCable

The `format` option has been renamed to `message`.
The `Noticed::NotificationChannel` has been removed and an example channel is provided in the [ActionCable docs](docs/delivery_methods/action_cable.md).

#### Email Delivery Method

`method` is now a required option. Previously, it was inferred from the notification name but we've decided it would be better to be explicit.

#### FCM

The `format` option has been renamed to `json`.
The `device_tokens` option is now required and should return an Array of device tokens.
The `invalid_token` option replaces the `cleanup_device_tokens` method for handling invalid/expired tokens.

#### iOS

The `format` option has been renamed to `json`.
The `device_tokens` option is now required and should return an Array of device tokens.
The `invalid_token` option replaces the `cleanup_device_tokens` method for handling invalid/expired tokens.

#### Microsoft Teams

The `format` option has been renamed to `json`.

#### Slack

The `format` option has been renamed to `json`.
The `url` option now defaults to `"https://slack.com/api/chat.postMessage` instead of `Rails.application.credentials.dig(:slack, :notification_url)`

#### Twilio Messaging

Twilio has been renamed to `:twilio_messaging` to make room for `:twilio_voice` and other services they may provide in the future.
The `format` option has been renamed to `json`.

#### Vonage SMS

Vonage has been renamed to `:vonage_sms` to make room for other Vonage services in the future.
The `format` option has been renamed to `json` and is now required.
