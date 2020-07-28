require 'test_helper'

class BlankNotification < Noticed::Base
end

class ApplicationNotification < Noticed::Base
  include Noticed::Database
end

class DbNotification < ApplicationNotification
end

class EmailNotification < ApplicationNotification
  include Noticed::Email
end

class Noticed::Test < ActiveSupport::TestCase
  test "notification has delivery methods" do
    assert BlankNotification.delivery_methods.is_a? Array
  end

  test "can add delivery methods" do
    assert_equal [:database], DbNotification.delivery_methods
  end

  test "delivery methods are inherited separately" do
    assert_equal [], BlankNotification.delivery_methods
    assert_equal [:database], DbNotification.delivery_methods
    assert_equal [:database, :email], EmailNotification.delivery_methods
  end

  test "stores data passed in" do
    notification = DbNotification.new(foo: :bar)
    assert_equal :bar, notification.data[:foo]
  end

  test "implements database method" do
    assert Noticed::Database.method_defined?(:deliver_with_database)
  end
end
