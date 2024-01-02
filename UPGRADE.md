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
  attributes = notification.attributes.slice(:id, :type, :params)
  attributes[:recipients_attributes] = {recipient_type: notification.recipient_type, recipient_id: notification.recipient_id, read_at: notification.read_at)
  Noticed::Notification.create(attributes)
end
```

After migrating, you can drop the old notifications table and model.

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