# Extending Noticed

Noticed includes lazy load hooks that can be used to extend it's models and functionality.

### Example: Multitenancy

This example adds multitenancy support to Noticed models so they have an `account:belongs_to` association.

```ruby
ActiveSupport.on_load :noticed_event do
  belongs_to :account

  # Set account association from params
  def self.with(params)
    account = params.delete(:account) || Current.account
    record = params.delete(:record)

    # Instantiate Noticed::Event with account:belongs_to
    new(account: account, params: params, record: record)
  end

  def recipient_attributes_for(recipient)
    super.merge(account_id: account&.id || recipient.personal_account&.id)
  end
end

ActiveSupport.on_load :noticed_notification do
  belongs_to :account
  delegate :message, to: :event
end
```
