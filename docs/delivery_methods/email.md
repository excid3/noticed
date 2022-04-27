### Email Delivery Method

Sends an email notification. Emails will always be sent with `deliver_later`

`deliver_by :email, mailer: "UserMailer"`

##### Options

- `mailer` - **Required**

  The mailer that should send the email

- `method: :invoice_paid` - _Optional_

  Used to customize the method on the mailer that is called

- `format: :format_for_email` - _Optional_

  Use a custom method to define the params sent to the mailer. `recipient` will be merged into the params.

- `enqueue: false` - _Optional_

  Use `deliver_later` to queue email delivery with ActiveJob. This is `false` by default as each delivery method is already a separate job.

##### ActionMailer::Preview

Use `YourMailer.with({ recipient: user }).mailer_method_name` to set up a `ActionMailer::Preview`. And you can pass any number of params into the `Hash` but you will need the recipient key.

```ruby
# test/mailers/previews/comment_mailer_preview.rb
class CommentMailerPreview < ActionMailer::Preview
  def mailer_method_name
    CommentMailer.with({ recipient: User.first }).mailer_method_name
  end
end
```
