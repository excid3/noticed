### Email Delivery Method

Sends an email notification. Emails will always be sent with `deliver_later`

`deliver_by :email, mailer: "UserMailer"`

##### Options

* `mailer` - **Required**

  The mailer that should send the email

* `method: :invoice_paid` - *Optional*

  Used to customize the method on the mailer that is called

* `format: :format_for_email` - *Optional*

  Use a custom method to define the params sent to the mailer. `recipient` will be merged into the params.


