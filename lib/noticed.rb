require "noticed/version"
require "noticed/engine"

require "zeitwerk"

loader = Zeitwerk::Loader.for_gem(warn_on_extra_files: false)
loader.ignore("#{__dir__}/generators")
loader.setup

module Noticed
  include ActiveSupport::Deprecation::DeprecatedConstantAccessor

  def self.deprecator # :nodoc:
    @deprecator ||= ActiveSupport::Deprecation.new
  end

  deprecate_constant :Base, "Noticed::Event", deprecator: deprecator

  module DeliveryMethods
    include ActiveSupport::Deprecation::DeprecatedConstantAccessor
    deprecate_constant :Base, "Noticed::DeliveryMethod", deprecator: Noticed.deprecator
  end

  mattr_accessor :parent_class
  @@parent_class = "Noticed::ApplicationJob"

  class ValidationError < StandardError; end

  class ResponseUnsuccessful < StandardError
    attr_reader :response

    def initialize(response, url, args)
      @response = response
      @url = url
      @args = args

      super("POST request to #{url} returned #{response.code} response:\n#{response.body.inspect}")
    end
  end
end
