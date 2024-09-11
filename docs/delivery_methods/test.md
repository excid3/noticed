# Test Delivery Method

Saves deliveries for testing.

## Usage

```ruby
class CommentNotification
  deliver_by :test
end
```

```ruby
Noticed::DeliveryMethods::Test.deliveries #=> []
```
