task start_app: [ :environment ] do
  INPUT_ARGS = ARGV

  def self.get_csv_data(csv_path)
    csv_items = []
    File.open(csv_path, mode="r") do |text_content|
      # Iterate through each line in text
      row = []
      text_content.read.each_line do |line|
        row.append(line.split(','))
      end
      csv_items.append(row)
    end
    csv_items
  end

  # Given a list of data containing times, prepends 0's to the time
  # portion of potential timestamps to be inserted.
  def self.reformat_work_order_timestamps(rows, target_index)

    # Iterate through rows of data
    rows.each_with_index do |row, i|

      # Get the string at target_index into current array and split by whitespace
      # to get date and time, respectively
      time_contents = row.at(target_index).split(" ")

      # raise an error if contents of time field doesn't have
      # both a date and a time (separated by whitespace)
      if time_contents.length != 2
        raise("Error parsing time contents for work order #{row.at(0)} : '#{time_contents.to_s}'")
      end

      # If the given time is of length 4, then it could be missing a leading 0.
      if time_contents[1].length == 4

        # Append leading 0 to time and replace data[i] with result.
        time_contents[1].insert(0, "0")
        rows[i] = time_contents.join(" ")

      elsif time_contents[1].length != 5
        raise("Error parsing time contents: Time should be provided as either (HH:mm) or (H:mm), got #{time}")
      end
    end
  end

  locations_path = "storage/locations.csv"
  technicians_path = "storage/technicians.csv"
  work_orders_path = "storage/work_orders.csv"

  # Load data from csv
  locations_data = self.get_csv_data(locations_path).at(0)
  technicians_data = self.get_csv_data(technicians_path).at(0)
  work_orders_data = self.get_csv_data(work_orders_path).at(0)

  # Strip headers from CSV data
  locations_data = locations_data.drop(1)
  technicians_data = technicians_data.drop(1)
  work_orders_data = work_orders_data.drop(1)

  # Reformat work order timestamps by prepending a "0" at the
  # last third index of work_orders_data
  work_orders_data = self.reformat_work_order_timestamps(
    work_orders_data, target_index=-3)
  # Insert locations into db

  # Insert technicians into db
  technicians_data.each { |technician|


    entry = Technicians.new
    entry.id = technician.at(0)
    entry.name = technician.at(1)
    entry.save!
  }
  locations_data.each { |location|

    entry = Locations.new
    entry.id = location.at(0)
    entry.name = location.at(1)
    entry.city = location.at(2)
    entry.save!
  }
  # Insert work_orders into db
  work_orders_data.each { |order|
    entry = Workorders.new
    entry.id = order.at(0)
    entry.technician_id = order.at(1)
    entry.location_id = order.at(2)
    entry.date = order.at(3)
    entry.duration = order.at(4)
    entry.price = order.at(5)
    entry.save!
  }
end