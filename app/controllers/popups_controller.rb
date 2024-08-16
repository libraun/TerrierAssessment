class PopupsController < ApplicationController
  before_action :set_popup, only: %i[ show edit update destroy ]

  # GET /popups or /popups.json
  def index
    @popups = Popup.all
  end

  # GET /popups/1 or /popups/1.json
  def show
  end

  # GET /popups/new
  def new
    @popup = Popup.new
  end

  # GET /popups/1/edit
  def edit
  end

  # POST /popups or /popups.json
  def create
    @popup = Popup.new(popup_params)

    respond_to do |format|
      if @popup.save
        format.html { redirect_to popup_url(@popup), notice: "Popup was successfully created." }
        format.json { render :show, status: :created, location: @popup }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @popup.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /popups/1 or /popups/1.json
  def update
    respond_to do |format|
      if @popup.update(popup_params)
        format.html { redirect_to popup_url(@popup), notice: "Popup was successfully updated." }
        format.json { render :show, status: :ok, location: @popup }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @popup.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /popups/1 or /popups/1.json
  def destroy
    @popup.destroy!

    respond_to do |format|
      format.html { redirect_to popups_url, notice: "Popup was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_popup
      @popup = Popup.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def popup_params
      params.require(:popup).permit(:name, :time)
    end
end
