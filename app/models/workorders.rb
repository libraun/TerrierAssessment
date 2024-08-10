class Workorders < ApplicationRecord
  attr_readonly :id!, :technician_id?, :location_id?,
                :time!, :duration!, :price!
end