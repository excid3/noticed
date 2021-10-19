### Database Delivery Method

Writes notification to the database.

`deliver_by :database`

**Note:** Database notifications are special in that they will run before the other delivery methods. We do this so you can reference the database record ID in other delivery methods. For that same reason, the delivery can't be delayed (via the `delay` option) or an error will be raised.

##### Options

* `association` - *Optional*

  The name of the database association to use. Defaults to `:notifications`

* `format: :format_for_database` - *Optional*

  Use a custom method to define the attributes saved to the database


