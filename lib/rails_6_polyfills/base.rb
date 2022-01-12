# The following implements polyfills for Rails < 6.0
module ActionCable
  # If the Rails 6.0 ActionCable::TestHelper is missing then allow it to autoload
  unless ActionCable.const_defined? :TestHelper
    autoload :TestHelper, "rails_6_polyfills/actioncable/test_helper.rb"
  end
  # If the Rails 6.0 test SubscriptionAdapter is missing then allow it to autoload
  unless ActionCable::SubscriptionAdapter.const_defined? :Test
    module SubscriptionAdapter
      autoload :Test, "rails_6_polyfills/actioncable/test_adapter.rb"
    end
  end
end

# If the Rails 6.0 ActionJob Serializers are missing then load support for them
unless ActiveJob.const_defined?(:Serializers)
  require "rails_6_polyfills/activejob/serializers"
end
