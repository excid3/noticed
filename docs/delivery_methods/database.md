### Database Delivery Method

Writes notification to the database.

`deliver_by :database`

**Note:** Database notifications are special in that they will run before the other delivery methods. We do this so you can reference the database record ID in other delivery methods. For that same reason, the delivery can't be delayed (via the `delay` option) or an error will be raised.

##### Options

* `association` - *Optional*

  The name of the database association to use. Defaults to `:notifications`

* `attributes:` - *Optional*

  Pass a symbol or callable object to define custom attributes to save to the database record.

##### Examples

```ruby
class CommentNotification
  deliver_by :database do |config|
    config.association = :notifications

    config.attributes = ->{
      { column: value }
    }
  end
end
```

```ruby
CommentNotification.with(record: @post).deliver(user)
```
