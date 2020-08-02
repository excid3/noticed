module Noticed
  class Coder
    def self.load(data)
      ActiveJob::Arguments.send(:deserialize_argument, data)
    end

    def self.dump(data)
      ActiveJob::Arguments.send(:serialize_argument, data)
    end
  end
end
