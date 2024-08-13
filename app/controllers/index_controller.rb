class IndexController < ApplicationController
  attr_accessor :target_table_str, :current_table

  def index
    @table_options = %w[Locations Technicians Workorders]
  end

  def show
    @table_options = %w[Locations Technicians Workorders]

    case params[:target_table_str]
    when @table_options.at(0)
      params[:current_table] = Locations.all
    when @table_options.at(1)
      params[:current_table] = Technicians.all
    when @table_options.at(2)
      params[:current_table] = Workorders.all
    else
      params[:current_table] = Locations.all
    end

    respond_to do |format|
      format.html { render :index }
    end
  end
end
