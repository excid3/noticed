$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "noticed/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name = "noticed"
  spec.version = Noticed::VERSION
  spec.authors = ["Chris Oliver"]
  spec.email = ["excid3@gmail.com"]
  spec.homepage = "https://github.com/excid3/noticed"
  spec.summary = "Notifications for Ruby on Rails applications"
  spec.description = "Database, browser, realtime ActionCable, Email, SMS, Slack notifications, and more for Rails apps"
  spec.license = "MIT"

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", ">= 6.0.0"
  spec.add_dependency "http", ">= 4.0.0"

  spec.add_development_dependency "pg"
  spec.add_development_dependency "standard"
end
