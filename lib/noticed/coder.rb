require "active_job/arguments"

module Noticed
  class Coder
    # Rails 8.2+ (globalid 1.4+) raises GlobalID::Locator::RecordNotFound for missing records
    # instead of ActiveRecord::RecordNotFound
    RECORD_NOT_FOUND_ERRORS = [ActiveRecord::RecordNotFound].tap do |errors|
      errors << GlobalID::Locator::RecordNotFound if defined?(GlobalID::Locator::RecordNotFound)
    end.freeze

    def self.load(data)
      return if data.nil?
      ActiveJob::Arguments.send(:deserialize_argument, data)
    rescue *RECORD_NOT_FOUND_ERRORS => error
      {noticed_error: error.message, original_params: data}
    end

    def self.dump(data)
      return if data.nil?
      if ActiveJob::Arguments.respond_to?(:serialize_argument, true)
        ActiveJob::Arguments.send(:serialize_argument, data)
      else
        ActiveJob::Arguments.serialize(data)
      end
    end
  end
end
