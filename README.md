# Noticed - Notifications for your Ruby on Rails app.

Currently we support these notification delivery methods out of the box:

* Database
* Email
* Websocket (realtime)
* Twilio (SMS)
* Vonage / Nexmo (SMS)

And you can easily add new notification types for any other delivery methods.

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'noticed'
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install noticed
```

## Usage

You can define a Notification as a class that inherits from Noticed::Base. To add delivery methods, simply `include` the module for the delivery methods you would like to use.

```ruby
class CommentNotification < Noticed::Base
  include Noticed::Database
  include Noticed::Websocket
end
```

To send a notification to a user:

```ruby
notification = CommentNotification.new(comment: @comment.to_gid)
notification.notify(@comment.post.author)
```

This will instantiate a new notification with the `comment` global ID stored in the metadata. 

Each delivery method is able to transfrom this metadata that's best for the format. For example, the database may simply store the comment so it can be linked when rendering in the navbar. The websocket mechanism may transform this into a browser notification or insert it into the navbar.

## Delivery Methods

The delivery methods are designed to be overriden so that you can customi1ze the notification for each medium. 

For example, emails will require a subject, body, and email address while an SMS requires a phone number and simple message. You can define the formats for each of these in your Notification and the delivery method will handle the processing of it.

Simply `include` any of these modules in your notification to add it as a delivery method.

#### `Noticed::Database`

Writes notification to the database.

#### `Noticed::Email`
Sends an email notification.

#### `Noticed::Slack`
Sends a Slack notification via webhook.

#### `Noticed::Twilio`
Sends an SMS notification via Twilio.

#### `Noticed::Vonage`
Sends an SMS notification vai Vonage / Nexmo.

#### `Noticed::Websocket`
Sends a notification to the browser via websockets (typically ActionCable channels).

### User Preferences

Each delivery method implements a `deliver_with_#{name}` method that receives the recipient as the first argument. You can override this method to check the user's preferences and skip processing if they have disabled that type of notification.

For example:

```ruby
class CommentNotification < Noticed::Base
  include Noticed::Database
  include Noticed::Email
  
  def deliver_with_email(recipient)
    return if recipient.email_notifications?
    super
  end
end
```



## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
