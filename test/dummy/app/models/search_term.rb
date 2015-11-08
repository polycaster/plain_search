class SearchTerm < ActiveRecord::Base
  belongs_to :findable, polymorphic: true
end
