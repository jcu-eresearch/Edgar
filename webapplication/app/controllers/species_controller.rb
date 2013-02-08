class SpeciesController < ApplicationController

  # GET /species

  def index
    @species = Species.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @species }
    end
  end

  def show
    @species = Species.find(params[:id])

    respond_to do |format|
      format.text { render :text => @species.get_wkt(params) }
      format.json {
        if params[:as_geo_json]
          render :json => @species.get_geo_json(params)
        else
          render :json => @species
        end
      }
    end
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
      format.html { render :layout => 'full_screen_map' }
    end
  end

  # GET /species/autocomplete?term=:my_search_term

  def autocomplete
    term = params[:term]
    search_result = Species.search_by_common_name_or_scientific_name(term)

    respond_to do |format|
      format.json { render json: search_result.map { |el| el.attributes } }
    end
  end

end
