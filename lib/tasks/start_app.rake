task start_app: [ :environment ] do
  INPUT_ARGS = ARGV

  Rake::Task["db:drop"].invoke
  Rake::Task["db:create"].invoke

  Rake::Task["db:schema:load"].invoke
  # Extracts rows from csv file.
  #
  # @param csv_path The (string) path, separated by newline characters
  # @return A list of rows from the (.csv) path, EXCLUDING headers.
  def self._get_csv_values(csv_path)
    csv_items = []
    File.open(csv_path, mode="r") do |text_content|
      # Iterate through each line in text, appending rows to output
      text_content.read.each_line(chomp: true) do |line|
        # Split line by comma and append to result
        csv_row = line.split(",")
        csv_items.append(csv_row)
      end
    end
    # Return all rows from csv file EXCEPT headers.
    csv_items.drop(1)
  end

  # Drop all table records, starting with dependent records
  Workorder.destroy_all
  Location.destroy_all
  Technician.destroy_all

  # Drop trigger to remove entries with an invalid date
  ActiveRecord::Base.connection.execute(
    "DROP TRIGGER IF EXISTS comp_date ON workorders CASCADE;")
  # Drop function that generates comp_date trigger
  ActiveRecord::Base.connection.execute(
    "DROP FUNCTION IF EXISTS create_trigger;")
  # PLPGSQL function that returns a trigger to check each row in workorders for
  # an invalid time (i.e., an appointment that occurs before the last chronological
  # appointment is set to end)

  # Specifically, this function checks to see whether the time for the next workorder
  # (for the given technician) overlaps with the time for the NEW workorder plus its duration.
  # If the NEW time + duration is greater than the next workorder begin time,
  # then the NEW workorder is dropped.
  trigger_function_def = <<~TEXT
    CREATE FUNCTION create_trigger() RETURNS TRIGGER AS $$
    DECLARE
      next_workorder_begin TIME;
      new_workorder_end TIME;
    BEGIN
      SELECT date::time FROM workorders INTO next_workorder_begin
        WHERE date::time > NEW.date::time and technician_id = NEW.technician_id
      ORDER BY date LIMIT 1;
      new_workorder_end := NEW.date + (NEW.duration * interval '1 minute');
      IF new_workorder_end > next_workorder_begin THEN RETURN NULL;
      END IF;
      RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;
  TEXT
  # PLPGSQL trigger that executes previous function on each row
  # when a new entry is inserted or deleted. (See above for details)
  trigger_def = <<~TEXT
    CREATE TRIGGER comp_date
      BEFORE INSERT OR UPDATE ON workorders
      FOR EACH ROW
      EXECUTE FUNCTION create_trigger();
  TEXT

  # Create previous trigger and function.
  ActiveRecord::Base.connection.execute(trigger_function_def)
  ActiveRecord::Base.connection.execute(trigger_def)

  # Load data from csv files.
  locations_data = self._get_csv_values("storage/locations.csv")
  technicians_data = self._get_csv_values("storage/technicians.csv")
  workorders_data = self._get_csv_values("storage/work_orders.csv")

  # Insert technicians into db.
  technicians_data.each { |technician|
    entry = Technician.create!(
      id: technician.at(0), name: technician.at(1))
    entry.save!
  }

  # Insert locations into db.
  locations_data.each { |location|
    entry = Location.create!(
      id: location.at(0), name: location.at(1), city: location.at(2))
    entry.save!
  }

  # Insert work_orders into db.
  workorders_data.each { |order|
    date_str = order.at(3)

    # A 2-tuple which represents the date and the time, respectively
    datetime = date_str.split(" ")

    # Because of how Ruby parses Time objects, we need to
    # preprocess the "year" part of each datetime
    datepart = datetime[0].split("/")

    # If the "year" part comprises only two characters, then we need to add
    # "20" (the current century) as a prefix.
    if datepart[-1].length == 2
      # Add prefix to year
      datepart[-1] = "20" + datepart[-1]

      # Join results to produce the original date, with "20" prepended to the year
      datepart = (datepart * "/").to_s
      date_str = ([ datepart, datetime[1] ] * " ").to_s
    end

    # Format the time according to the csv, and subtract the offset of Ruby's standard timezone
    # to get the final date.
    date = Time.strptime(date_str, "%m/%d/%Y %H:%M") - 5.hours
    date = date.to_s

    entry = Workorder.create!(
      id: order.at(0), technician_id: order.at(1), location_id: order.at(2),
      date: date, duration: order.at(4), price: order.at(5))
    entry.save!
  }
end
