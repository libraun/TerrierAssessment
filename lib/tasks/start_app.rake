task :start_app => [ :environment ] do
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

  def self.adjust_work_order_times(data)

    data.each_with_index do |item, i|
      time_contents = item.at(-3).split(' ')

      if time_contents.length != 2
        raise("Error parsing time contents for work order #{item.at(0)} : '#{time_contents.to_s}'")
      end
      if time_contents[1].length == 4
        time_contents[1].insert(0, '0')
      elsif time_contents[1].length != 5
        raise("Error parsing time contents: Time should be provided as either (HH:mm) or (H:mm), got #{time}")
      end
      data[i] = time_contents.join(' ')
    end
  end

  locations_path = "storage/locations.csv"
  technicians_path = "storage/technicians.csv"
  work_orders_path = "storage/work_orders.csv"

  locations_data = self.get_csv_data(locations_path).at(0)
  technicians_data = self.get_csv_data(technicians_path)
  work_orders_data = self.get_csv_data(work_orders_path)

  locations_headers = locations_data.at(0)
  puts(locations_data.to_s)
  locations_data = locations_data.drop(1)
  puts(locations_data.to_s)

  technicians_headers = technicians_data.at(0)
  technicians_data = technicians_data.drop(1)

  work_orders_headers = work_orders_data.at(0)
  work_orders_data = work_orders_data.drop(1)
  work_orders_data = self.adjust_work_order_times(work_orders_data)
  puts(locations_data.to_s)
  locations_data.each { |location|
    puts location.at(0).to_i.to_param
    location = Locations.create( {id: 1    })
    location.save

    #   print(location.id!)
  }
  File.write("ad.txt", "a")



end