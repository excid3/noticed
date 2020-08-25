### Unreleased

### 1.2.13

* [NEW] Validate that delivery by emails (`deliver_by :email`) always have a mailer specified.
* [NEW] Allow validating options in custom delivery methods
* [FIX] Add `null: false` to `type` column in Notification migration

### 1.2.12

* [NEW] Add `noticed:delivery_method` generator to create custom delivery methods.

### 1.2.11

* [FIX] Use ActiveRecord configuration to detect adapter without establishing a database connection

### 1.2.10

* [NEW] Add Noticed::TextCoder for databases without json support
* [NEW] Update generator to make params column json for MySQL, jsonb for Postgres, and text for everything else
* [FIX] Keyword args warning for delivery methods is now fixed

### 1.2.9

* [FIX] Recipient is available in `if` & `else` options

### 1.2.8

* [FIX] Use form data when sending to Twilio

### 1.2.7

* [NEW] Add i18n_scope - @rbague
* [NEW] Add `params` for specifying multiple required params - @rbague
* [NEW] Allow passing in object or string for action_cable channel option - @excid3
* [FIX] Skip JSON parse if deserializing was already done - @excid3

### 1.2.6

* [FIX] Fix Slack default params #13 - @itsderek23

### 1.2.5

* [FIX] Improve serializer to handle text, json, and jsonb columns

### 1.2.4

* Include `record` in email params by default

### 1.2.3

* Adds `recipient` method on notification so they can access it during delivery. Useful when formatting to include recipient details
* Merge `recipient` into params by default when delivering email notifications

### 1.2.2

* [FIX] Remove duplicates when delivering notification to multiple receipients

### 1.2.1

* [NEW] Allow delivering notification to multiple recipients

### 1.2.0

* Translation helpers
* Allow notification objects to call Rails url helpers directly
* Add `noticed:notification` generator
* Allow changing database association name with `deliver_by :database, association: :notifications`
* Add `Noticed::Model` concern for database notifications
* Add notification database model generator

### 1.1.0

* Callbacks for notification around delivery
* Callbacks for delivery methods around delivery


### 1.0.0

* Initial release
