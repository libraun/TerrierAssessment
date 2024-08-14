class IndexController < ApplicationController
  attr_accessor :headers, :current_table
  def index
    technician_names = []
    Technician.all.each do |technician|
      technician_names.append(technician["name"])
    end

    params[:headers] = technician_names

    query = """
      SELECT * FROM workorders
        INNER JOIN technicians ON technicians.id = technician_id AND name = '%s'
      ORDER BY (workorders.date, workorders.time) """

    records = {}
    technician_names.each do |name|
      records[name] = ActiveRecord::Base.connection.execute(query % name)
    end
    # The list of tables that the user may select from.

    # Assign the current table view to the user's selection and redraw
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
    _query = """
      SELECT * FROM workorders
        INNER JOIN technicians ON technicians.id = technician_id AND name = 'Juan Garcia'
      ORDER BY (workorders.date, workorders.time) """
    _records = ActiveRecord::Base.connection.execute(_query)
    # Assign the current table view to the user's selection and redraw
    params[:current_table] = _records

    respond_to do |format|
      format.html { render :index }
    end
  end
end
