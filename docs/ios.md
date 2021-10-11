# iOS Notifications

* Message
* Title/description
* Sound
* "Silent"
* Custom payload (for routing, nested)

### Creating an APNS app

Add to `config/initializers/rpush.rb`

```ruby
Rpush::Apnsp8::App.find_or_create_by(name: "ios_app") do |app|
  app.environment = %w[development test].include?(Rails.env) ? "development" : "production"
  app.apn_key = File.read(Rails.root.join("config/ios/#{app.environment}.p8")) # development.p8 and production.p8
  app.apn_key_id = Rails.application.credentials.dig(:ios, :apn_key_id) # encryption Key ID provided by apple
  app.team_id = Rails.application.credentials.dig(:ios, :team_id) # e.g. ABCDE12345
  app.bundle_id = Rails.application.credentials.dig(:ios, :bundle_id) # the unique bundle id of the app, e.g. com.example.appname
  app.connections = 1 # https://github.com/rpush/rpush/wiki/Why-open-multiple-connections-to-the-APNs%3F
end
```
