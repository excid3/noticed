appraise "rails-6-1" do
  gem "rails", "~> 6.1.0"
  gem "sqlite3", "~> 1.7"
  gem "activerecord-trilogy-adapter"

  # Ruby 3.4 drops these default gems
  gem "bigdecimal"
  gem "drb"
  gem "mutex_m"

  # Fixes uninitialized constant ActiveSupport::LoggerThreadSafeLevel::Logger (NameError)
  gem "concurrent-ruby", "< 1.3.5"
end

appraise "rails-7-0" do
  gem "rails", "~> 7.0.0"
  gem "sqlite3", "~> 1.7"
  gem "activerecord-trilogy-adapter"

  # Ruby 3.4 drops these default gems
  gem "bigdecimal"
  gem "drb"
  gem "mutex_m"

  # Fixes uninitialized constant ActiveSupport::LoggerThreadSafeLevel::Logger (NameError)
  gem "concurrent-ruby", "< 1.3.5"
end

appraise "rails-7-1" do
  gem "rails", "~> 7.1.0"
  gem "sqlite3", "~> 1.7"
  gem "trilogy"
end

appraise "rails-7-2" do
  gem "rails", "~> 7.2.0"
  gem "sqlite3", "~> 1.7"
  gem "trilogy"
end

appraise "rails-8-0" do
  gem "rails", "~> 8.0.0"
  gem "sqlite3", "~> 2.0"
  gem "trilogy"
end

appraise "rails-main" do
  gem "rails", github: "rails/rails", branch: "main"
  gem "sqlite3", "~> 2.0"
  gem "trilogy"
end
