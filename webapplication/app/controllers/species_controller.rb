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
        render :json => @species
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

  # GET /species/autocomplete?term=:term

  def autocomplete
    term = params[:term]
    search_result = Species.search_by_common_name_or_scientific_name(term)

    respond_to do |format|
      format.json { render json: search_result }
    end
  end

  # POST /species/get_next_job_and_assume_queued
  #
  # Get the highest priority job to model. Assumes that the
  # requestor will queue the job for modelling at their end.

  def get_next_job_and_assume_queued
    @species = Species.next_job()

    if @species
      @species.current_model_status = "QUEUED"
      @species.current_model_queued_time = Time.now()
      if not @species.first_requested_remodel.nil?
        @species.current_model_importance = 2
      else
        @species.current_model_importance = 1
      end
      @species.save()

      render text: @species.id, status: 200
    else
      render text: "No species modelling required.", status: 204
    end
  end

  # GET /species/occurrences(.text|.json)
  #
  # Returns the species occurrences in either geo_json
  # or WKT

  def occurrences
    @species = Species.find(params[:id])

    respond_to do |format|
      format.text { render :text => @species.get_occurrences_wkt(params) }
      format.json {
        render :json => @species.get_occurrences_geo_json(params)
      }
    end
  end

  # GET /species/vettings(.text|.json)
  #
  # Returns the species vettings in either geo_json
  # or WKT

  def vettings
    @species = Species.find(params[:id])

    respond_to do |format|
      format.text { render :text => @species.get_vettings_wkt(params) }
      format.json {
        render :json => @species.get_vettings_geo_json(params)
      }
    end
  end

  # POST /species/job_status/:id
  #
  # [:job_status] The new job status for this species
  # [:job_status_message] A human readable description of the current job status.
  # [:dirty_occurrences]  How many dirty occurrences existed when this job was queued.

  def job_status
    @species = find(params[:id])

    @species.update_job_status!(params[:job_status], params[:job_status_message], params[:dirty_occurrences])

    render text: @species.id, status: 200
  end

end
