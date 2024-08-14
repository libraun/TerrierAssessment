task start_app: [ :environment ] do

  INPUT_ARGS = ARGV

  # Extracts rows from csv file.
  # @param csv_path
  def self._get_csv_values(csv_path)

    csv_items = []
    File.open(csv_path, mode="r") do |text_content|

      # Iterate through each line in text, appending rows
      # to output
      text_content.read.each_line(chomp: true) do |line|

        csv_row = line.split(",")
        csv_items.append(csv_row)
      end
    end
    # Return all rows from csv file EXCEPT headers.
    csv_items.drop(1)
  end

  # Drop table records (for idempotency)
  Workorder.destroy_all
  Location.destroy_all
  Technician.destroy_all

  # Load data from csv
  locations_data = self._get_csv_values("storage/locations.csv")
  technicians_data = self._get_csv_values("storage/technicians.csv")
  workorders_data = self._get_csv_values("storage/work_orders.csv")

  # Insert technicians into db
  technicians_data.each { |technician|
    entry = Technician.create!(id: technician.at(0), name: technician.at(1))
    entry.save!
  }
  # Insert locations
  locations_data.each { |location|
    entry = Location.new
    entry.id = location.at(0)
    entry.name = location.at(1)
    entry.city = location.at(2)
    entry.save!
  }
  # Insert work_orders into db
  workorders_data.each { |order|
    entry = Workorder.new(id: order.at(0), technician_id: order.at(1))
    entry.location_id = order.at(2)
    datetime = order.at(3).split(" ")
    entry.date = datetime[0]
    entry.time = datetime[1]

    entry.duration = order.at(4)
    entry.price = order.at(5)
    entry.save!
  }
end