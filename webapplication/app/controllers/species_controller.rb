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

  # GET /species/autocomplete?term=:my_search_term

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
    species = Species.next_job()

    if species
      species.current_model_status = "QUEUED"
      species.current_model_queued_time = Time.now()
      if not species.first_requested_remodel.nil?
        species.current_model_importance = 2
      else
        species.current_model_importance = 1
      end
      species.save()

      render text: species.id, status: 200
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

=begin
  # POST /species/get_next_job_and_assume_queued
    
    /**
     * Updates the status of a running modelling job
     *
     * TODO: any auth on this? looks like a minor security hole
     * TODO: how do we handle failure? Just ignored it for the moment.
     *
     * Takes POST/PUT params:
     *  - job_status - a status code string
     *  - job_status_message - human readable (?) message for job_status
     *  - dirty_occurrences - value of num_dirty_occurrences when the job started
     */
    public function job_status($species_id) {
        $species = $this->Species->find('first', array(
            'conditions' => array('id' => $species_id)
        ));
        if($species === false)
            $this->dieWithStatus(404, 'No species found with given id');

        $jobStatus = $this->request->data('job_status');

        // Only process it if the jobStatus has changed.
        if ($jobStatus !== $species['Species']['current_model_status']) {

            // Starting a JOB
            if($jobStatus === 'QUEUED') {
                // Update current model info for species
                $species['Species']['current_model_status'] = $jobStatus;
                // Record when the job started
                $species['Species']['current_model_queued_time'] = date(DATE_ISO8601);
                // Record the importance of the job
                if($species['Species']['first_requested_remodel'] !== null) {
                    $species['Species']['current_model_importance'] = 2;
                } else {
                    $species['Species']['current_model_importance'] = 1;
                }

            // Finished a JOB
            } elseif($jobStatus === 'FINISHED_SUCCESS' or $jobStatus === 'FINISHED_FAILURE') {
                // Get job status message
                $jobStatusMessage = $this->request->data('job_status_message');

                // Update last completed model info
                $species['Species']['last_completed_model_queued_time']   = $species['Species']['current_model_queued_time'];
                $species['Species']['last_completed_model_finish_time']   = date(DATE_ISO8601);
                $species['Species']['last_completed_model_importance']    = $species['Species']['current_model_importance'];
                $species['Species']['last_completed_model_status']        = $jobStatus;
                $species['Species']['last_completed_model_status_reason'] = $jobStatusMessage;

                // Update last successfully completed model info
                if($jobStatus === 'FINISHED_SUCCESS') {
                    $species['Species']['last_successfully_completed_model_queued_time'] = $species['Species']['last_completed_model_queued_time'];
                    $species['Species']['last_successfully_completed_model_finish_time'] = $species['Species']['last_completed_model_finish_time'];
                    $species['Species']['last_successfully_completed_model_importance']  = $species['Species']['last_completed_model_importance'];

                    // Only update the dirty_occurrences record if
                    // the model that was ran cleared all our dirty occurrences.
                    $occurrencesCleared = (int)$this->request->data('dirty_occurrences');
                    if ($species['Species']['num_dirty_occurrences'] === $occurrencesCleared) {
                        $species['Species']['num_dirty_occurrences'] = 0;
                    }
                }

                $species['Species']['current_model_status'] = null;
                $species['Species']['current_model_importance'] = null;
                $species['Species']['current_model_queued_time'] = null;
                $species['Species']['first_requested_remodel'] = null;

            // Part way through a JOB
            } else {
                $species['Species']['current_model_status'] = $jobStatus;
            }

            $this->Species->save($species);
        }

        $this->dieWithStatus(200);
    }
=end

end
