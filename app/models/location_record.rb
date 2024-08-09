class Location < ApplicationRecord

  self.table_name = "locations"

  attr_readonly :id!, :name!
end
