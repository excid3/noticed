# frozen_string_literal: true

require "test_helper"

class Noticed::Deliverable::DeliverByTest < ActiveSupport::TestCase
  class TestDelivery < Noticed::Deliverable::DeliverBy; end

  test "#perform? returns true when before_enqueue is missing" do
    config = ActiveSupport::OrderedOptions.new.merge({})
    assert_equal true, TestDelivery.new(:test, config).perform?({})
  end

  test "#perform? returns false when before_enqueue throws" do
    config = ActiveSupport::OrderedOptions.new.merge({})
    config.before_enqueue = -> { throw :abort }
    assert_equal false, TestDelivery.new(:test, config).perform?({})
  end

  test "#perform? returns true when before_enqueue does not throw" do
    config = ActiveSupport::OrderedOptions.new.merge({})
    config.before_enqueue = -> { false }
    assert_equal true, TestDelivery.new(:test, config).perform?({})
  end

  test "#perform? takes context into account" do
    config = ActiveSupport::OrderedOptions.new.merge({})
    config.before_enqueue = -> { throw :abort if key?(:test_value) }
    assert_equal false, TestDelivery.new(:test, config).perform?({test_value: true})
    assert_equal true, TestDelivery.new(:test, config).perform?({other_value: true})
  end
end
