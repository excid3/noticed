class ApplicationRecord < ActiveRecord::Base
  if respond_to?(:primary_abstract_class)
    primary_abstract_class
  else
    self.abstract_class = true
  end
end
