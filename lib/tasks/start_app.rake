task start_app: [ :environment ] do
  INPUT_ARGS = ARGV
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
        WHERE date > NEW.date and technician_id = NEW.technician_id
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
    entry = Workorder.create!(
      id: order.at(0), technician_id: order.at(1), location_id: order.at(2),
      date: order.at(3), duration: order.at(4), price: order.at(5))
    entry.save!
  }
end
