class Employee < ActiveRecord::Base
  belongs_to :company
  delegate :name, to: :company, prefix: true
end