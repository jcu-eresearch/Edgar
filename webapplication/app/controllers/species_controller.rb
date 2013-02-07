class SpeciesController < ApplicationController
  def index
    @species = Species.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @species }
    end
  end

  def show
  end

  # GET /species/map
  # GET /species/1/map
  def map
    @species = nil

    # Get the species provided if one was set
    if params[:id]
      @species = Species.find(params[:id])
    end

    respond_to do |format|
      format.html # map.html.erb
    end
  end
end
