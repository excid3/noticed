# Noticed Upgrade Guide

Follow this guide to upgrade your Noticed implementation to the next version

## Noticed 2.0

We've made some major changes to Noticed to simplify and support more delivery methods.

### Models

Instead of having models live in your application, Noticed v2 adds models managed by the gem.

```bash
rails noticed:install:migrations
rails db:migrate
```

To migrate your data to the new tables, loop through your existing notifications and create new records for each one

```ruby
Notification.find_each do |notification|
  attributes = notification.attributes.slice("id", "type", "params")
  attributes[:notifications_attributes] = [{recipient_type: notification.recipient_type, recipient_id: notification.recipient_id, seen_at: notification.read_at, read_at: notification.interacted_at}]
  Noticed::Event.create!(attributes)
end
```

class Notification < ActiveRecord::Base
  self.inheritance_column = nil
end

Notification.find_each do |notification|
  attributes = notification.attributes.slice("id", "type", "params")
  attributes[:notifications_attributes] = [{recipient_type: notification.recipient_type, recipient_id: notification.recipient_id, seen_at: notification.read_at, read_at: notification.interacted_at}]
  Noticed::Event.create!(attributes)
end

After migrating, you can drop the old notifications table and model.

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

Configuration for each delivery method can be contained within a block now. This improves organization but 

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

### Has Noticed Notifications

`has_noticed_notifications` has been removed in favor of the `record` polymorphic relationship that can be directly queried with ActiveRecord. You can add the necessary json query to your model(s) to restore the json query if needed.

We recommend backfilling the `record` association if your notification params has a primary related record and switching to a has_many association instead.

```ruby
class Comment < ApplicationRecord
  has_many :noticed_events, as: :record, dependent: :destroy, class_name: "Noticed::Event"
end
```

### Receipient Notifications Association

Recipients can be associated with notifications using the following. This is useful for displaying notifications in your UI.

```ruby
class User < ApplicationRecord
  has_many :notifications, as: :recipient, dependent: :destroy, class_name: "Noticed::Notification"
end
```