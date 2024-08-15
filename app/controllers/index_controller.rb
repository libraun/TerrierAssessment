class IndexController < ApplicationController
  attr_accessor :headers, :current_table
  def index
    technician_names = []
    Technician.all.each do |technician|
      technician_names.append(technician["name"])
    end
    params[:headers] = technician_names
    query = <<~TEXT
      SELECT * FROM workorders
        INNER JOIN technicians ON technicians.id = technician_id AND name = '%s'
      ORDER BY (workorders.date);
    TEXT
    records = {}
    technician_names.each { |name|
      records[name] = ActiveRecord::Base.connection.execute(query % name)
      times = []
      records[name].each { |row|
        times.append([ row["date"], row["duration"] ])
      }
      times.each.with_index { |pair, i|
        start_time = pair.at(0)
        end_time = start_time + pair.at(1).minutes
        if i != times.length - 1
          next_pair = times.at(i + 1)
          next_start_time = next_pair[0]
          difference = (next_start_time - end_time) / 1.minutes
          puts difference
        end
      }
    }
    params[:current_table] = records
    respond_to do |format|
      format.html { render :index }
    end
  end
  def show
    # Get a list of technician names as headers
    _names = Technician.all.each { |technician|
      technician["name"]
    }
    # The list of tables that the user may select from.
    _query = <<~TEXT
      SELECT * FROM workorders
        INNER JOIN technicians ON technicians.id = technician_id AND name = 'Juan Garcia'
      ORDER BY (workorders.date, workorders.time) 
    TEXT
    _records = ActiveRecord::Base.connection.execute(_query)
    # Assign the current table view to the user's selection and redraw
    params[:current_table] = _records
    respond_to do |format|
      format.html { render :index }
    end
  end
end
