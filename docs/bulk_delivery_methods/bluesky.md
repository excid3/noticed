# Bluesky Bulk Delivery Method

Create a Bluesky post.

## Usage

```ruby
class CommentNotification
  bulk_deliver_by :bluesky do |config|
    config.identifier = "username"
    config.password = "password"
    config.json = -> {
      {
        text: "Hello world!",
        createdAt: Time.current.iso8601
        # ...
      }
    }
  end
end
```
