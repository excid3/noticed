# Noticed Upgrade Guide

Follow this guide to upgrade your Noticed implementation to the next version

## Noticed 2.0

We've made some major changes to Noticed to simplify and support more delivery methods.

### Models

Instead of having models live in your application, Noticed v2 adds models managed by the gem.

Delete the `Notification` model from `app/models/notifications.rb`.

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
  attributes = notification.attributes.slice("id", "type")
  attributes[:type] = attributes[:type].sub("Notification", "Notifier"))
  attributes[:params] = Noticed::Coder.load(notification.params)
  attributes[:notifications_attributes] = [{recipient_type: notification.recipient_type, recipient_id: notification.recipient_id, seen_at: notification.read_at, read_at: notification.interacted_at}]
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

Notifiers - the class that delivers notifications
Notification - the database record of the notification

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
