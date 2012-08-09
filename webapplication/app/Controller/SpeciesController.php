<?php
App::uses('AppController', 'Controller');
App::uses('User', 'Model');
App::uses('Vetting', 'Model');

/**
 * Species Controller
 *
 * @property Species $Species
 */
class SpeciesController extends AppController {
    public $components = array('RequestHandler');
    public $helpers = array('Form', 'Html', 'Js', 'Time');

    const DOWNLOAD_URL_PREFIX = "https://eresearch.jcu.edu.au/tdh/datasets/Edgar/";

    // Don't allow a user to insert a vetting unless they are logged in.
    public function beforeFilter() {
        parent::beforeFilter();
        $this->Auth->deny(array('add_vetting'));
    }


    /**
     * index method
     *
     * @return void
     */
    public function index() {
        $this->set('title_for_layout', 'Species - Index');

        $this->set('species', $this->paginate());

        // Specify the output for the json view.
        $this->set('_serialize', 'species');
    }

    /**
     * view method
     *
     * @param string $id
     * @return void
     */
    public function view($id = null) {
        $this->set('title_for_layout', 'Species - View');

        $this->Species->recursive = 1;
        $this->Species->id = $id;
        if (!$this->Species->exists()) {
            throw new NotFoundException(__('Invalid species'));
        }
        $this->set('species', $this->Species->read(null, $id));

        // Specify the output for the json view.
        $this->set('_serialize', 'species');
    }

    /**
     * occurrences method
     *
     * @param string $id
     * @return void
     */
    public function occurrences($id = null) {
        $this->set('title_for_layout', 'Species - Occurrences');

        $this->Species->id = $id;
        if (!$this->Species->exists()) {
            throw new NotFoundException(__('Invalid species'));
        }

        $species = $this->Species->read(null, $id);
        $occurrences = $species['Occurrence'];

        $this->set('species', $species);
        $this->set('occurrences', $occurrences);

        // Specify the output for the json view.
        $this->set('_serialize', 'occurrences');

    }

    /**
     * geo_json_occurrences method
     *
     * Takes the following http_request_params:
     *  * bbox
     *
     * bbox is a comma seperated string representing the bounds of the user's view.
     * e.g. whole world, zoomed out:
     *      -607.5,-405,607.5,405
     *
     * e.g. bottom left corner of world, zoomed in:
     *      -198.984375,-102.65625,-123.046875,-52.03125
     *
     * 1st pair is the bottom left corner of the bounds.
     * 2nd pair is the top right corner of the bounds.
     *
     * Produces a GeoJSON object of type FeatureCollection.
     * Should only produce, at most, 1000 features.
     *
     * @param string $id
     * @return void
     */
    public function geo_json_occurrences($id = null) {
        $this->set('title_for_layout', 'Species - GeoJSON Occurrences');

        $this->Species->id = $id;
        if (!$this->Species->exists()) {
            throw new NotFoundException(__('Invalid species'));
        }

        // Look up the species provided
        $species = $this->Species->read(null, $id);

        // Check if we were provided a bbox (bounding box)
        $bbox = array();
        if ( array_key_exists('bbox', $this->request->query) ) {
            $bbox_param_string = $this->params->query['bbox'];
            $bbox_param_as_array = explode(',', $bbox_param_string);
            if ( sizeof($bbox_param_as_array) == 4 ) {
                $bbox = array(
                    "min_longitude" => $bbox_param_as_array[0],
                    "min_latitude"  => $bbox_param_as_array[1],
                    "max_longitude" => $bbox_param_as_array[2],
                    "max_latitude"  => $bbox_param_as_array[3],
                );
            }
        }

        // Check if clustered was set to true.
        // Default clustered to true
        $cluster_type = 'dotradius';

        if ( array_key_exists('clustered', $this->request->query) ) {
            $cluster_type = $this->request->query['clustered'];
        }

        $this->set('geo_object', $this->Species->toGeoJSONArray($bbox, $cluster_type));

        // Specify the output for the json view.
        $this->set('_serialize', 'geo_object');
    }

    /*
        Get the vetting geojson for the given species.

        By default, gets all vettings for given species id.

        Can be filtered to only include vettings by a specific user.
        Filter can be inversed (i.e. all vettings NOT by specific user).

        TODO: Remove magic numbers from the SQL LIMIT

        params:
        * species_id: the species to get the vettings for
        * by_user_id: get vettings by a specific user_id
        * inverse_user_id_filter: if set, will get vettings NOT by by_user_id
    */
    public function vetting_geo_json($species_id = null) {

        $this->Species->id = $species_id;
        if (!$this->Species->exists()) {
            throw new NotFoundException(__('Invalid species'));
        }

        // Process any filter variables
        $by_user_id = false;
        $inverse_user_id_filter = false;

        if (array_key_exists('by_user_id', $this->request->query)) {
            $by_user_id = (int)$this->request->query['by_user_id'];
        }

        if(array_key_exists('inverse_user_id_filter', $this->request->query)) {
            $inverse_user_id_filter = $this->request->query['inverse_user_id_filter'];
        }

        $results = null;

        if ($by_user_id and $inverse_user_id_filter) {
            $results = $this->Species->getDataSource()->execute(
                'SELECT id, ST_AsGeoJSON(area), classification, comment FROM vettings '.
                'WHERE species_id = ? AND user_id <> ? AND deleted is NULL '.
                'LIMIT 1000',
                array(),
                array($species_id, $by_user_id)
            );
        } elseif ($by_user_id) {
            $results = $this->Species->getDataSource()->execute(
                'SELECT id, ST_AsGeoJSON(area), classification, comment FROM vettings '.
                'WHERE species_id = ? AND user_id = ? AND deleted is NULL '.
                'LIMIT 1000',
                array(),
                array($species_id, $by_user_id)
            );
        } else {
            $results = $this->Species->getDataSource()->execute(
                'SELECT id, ST_AsGeoJSON(area), classification, comment FROM vettings '.
                'WHERE species_id = ? AND deleted is NULL '.
                'LIMIT 1000',
                array(),
                array($species_id)
            );
        }


        // Convert the received vettings into a geometry collection.
        $geo_json_features_array = array();

        if($results) {
            while ($row = $results->fetch(PDO::FETCH_NUM, PDO::FETCH_ORI_NEXT)) {
                $vetting_id = $row[0];
                $area_json  = $row[1];
                $classification = $row[2];
                $comment = $row[3];

                $properties_json_array = Vetting::getPropertiesJSONObject($classification);
                $properties_json_array['classification'] = $classification;
                $properties_json_array['vetting_id'] = $vetting_id;

                // decode the json
                array_push($geo_json_features_array, array('type' => 'Fetaure', 'geometry' => json_decode($area_json), 'properties' => $properties_json_array));
            }
        }

        $geo_json_object = array( 
                    'type' => 'FeatureCollection',
                    'features' => $geo_json_features_array
        );

        $geo_json = json_encode($geo_json_object);
        $this->set('geo_json', $geo_json_object);
        $this->set('_serialize', 'geo_json');
    }

    /*
        Insert vetting geojson for the given species.
    */
    public function add_vetting($species_id = null) {

        // Get the auth'd user.
        // NOTE: Prefilter means the user can't be here unless they are logged in.
        $user_id = $this->Auth->user('id');

        if ($this->request->is('post')) {
            $this->Species->recursive = 0;
            $this->Species->id = $species_id;
            if (!$this->Species->exists()) {
                throw new NotFoundException(__('Invalid species'));
            }
            $this->set('species', $this->Species->read(null, $species_id));

            // Specify the output for the json view.
            $this->set('_serialize', 'species');

            $jsonData = json_decode(utf8_encode(trim(file_get_contents('php://input'))), true);

            if ($jsonData !== null) {
                // At this point, we have the json data.
                // Do the work on it.
                $this->set('jsonData', $jsonData);
                $area = $jsonData['area'];
                $this->set('_serialize', 'jsonData');
                $comment = $jsonData['comment'];
                $classification = $jsonData['classification'];

                $dbo = $this->Species->Vetting->getDataSource();
                $escaped_area = $dbo->value($area);
                $dbo->execute(
                    "INSERT INTO vettings (user_id, species_id, comment, classification, area) VALUES ( ? , ? , ? , ? , ST_Multi(ST_Buffer( ( ST_GeomFromText(".$escaped_area.", 4326) ), 0) ) )",
                    array(),
                    array($user_id, $species_id, $comment, $classification)
                );

                $this->Species->markAsNeedingVetting($species_id);

                $this->dieWithStatus(200, '{ "result": "success" }');
            } else {
                $this->dieWithStatus(400, "Bad JSON Input");
            }
        }
    }

    /**
     * single_upload_json method
     *
     * @return void
     */
    public function single_upload_json() {
        $this->set('title_for_layout', 'Species - Single Species Upload (JSON)');

        // If user did a HTTP_POST, process the upload file
        if ($this->request->is('post')) {
            // File: data['Species']['upload_file'] => (array)
            $file = $this->request->data['Species']['upload_file'];

            // File's array:
            //   name => (name of file)
            //   type => (file type, e.g. image/jpeg)
            //   tmp_name => (file_path)
            //   error => 0
            //   size => (file_size in Bytes)
            $file_name = $file['name'];
            $file_type = $file['type'];
            $tmp_file_path= $file['tmp_name'];

            // Expected file type is application/json
            $file_contents = file_get_contents($tmp_file_path);
            $json_decoded_file_contents = json_decode($file_contents, true);

            if ($this->Species->saveAssociated($json_decoded_file_contents)) {
                $this->Session->setFlash(__('The species has been saved'));
                $this->redirect(array('action' => 'index'));
            } else {
                $this->Session->setFlash(__('The species could not be saved. Please, try again.'));
            }
        }
        // Else -> Fall through to render view (form to upload a single species json file)
    }

    /**
     * map method
     *
     * @param string $id
     * @return void
     */
    public function map($id = null) {
        $this->set('title_for_layout', 'Species - Map');
        if ($id == null) {
            $this->set('species', null);
        } else {
            $result = $this->Species->find('first', array(
                'conditions' => array('id' => $id)
            ));
            if($result !== false){
                $this->set('species', $this->_speciesToJson($result['Species']));
            } else {
                throw new NotFoundException(__('Invalid species'));
            }
        }

        // use the fullscreen map view
        $this->render('fullscreenmap');
    }


    /**
     * Returns JSON for a jQuery UI autocomplete box
     */
    public function autocomplete() {
        // get what the user typed in
        $partial = strtolower($this->request->query['term']);

        // query db
        $results = $this->Species->getDataSource()->execute(
            'SELECT * FROM '.
            '    (SELECT *, GREATEST(SIMILARITY(?, scientific_name), SIMILARITY(?, common_name)) AS match '.
            '     FROM species '.
            '     WHERE has_occurrences) AS matched_and_filtered_species '.
            'WHERE match > 0 '.
            'ORDER BY match DESC '.
            'LIMIT 20',
            array(),
            array($partial, $partial)
        );

        // convert $matched_species into json format expected by jquery ui
        $matched_species = array();
        foreach($results as $species){
            $matched_species[] = $this->_speciesToJson($species);
        }

        // render json
        $this->set('results', $matched_species);
        $this->set('_serialize', 'results');
    }

    /**
     * Return the next species to run a modelling job for.
     * Assumes requestor will start the job.
     */
    public function get_next_job_and_assume_queued() {
        if ($this->request->is('post')) {
            $species = $this->_next_job();

            if($species){
                // Update current model info for species
                $species['Species']['current_model_status'] = "QUEUED";
                // Record when the job started
                $species['Species']['current_model_queued_time'] = date(DATE_ISO8601);
                // Record the importance of the job
                if($species['Species']['first_requested_remodel'] !== null) {
                    $species['Species']['current_model_importance'] = 2;
                } else {
                    $species['Species']['current_model_importance'] = 1;
                }
                $this->Species->save($species);
                $this->dieWithStatus(200, $species['Species']['id']);
            } else {
                $this->dieWithStatus(204, 'No species modelling required.');
            }
        }
    }

    /**
     * Return next species to run a modelling job for
     */
    public function next_job() {

        $species = $this->_next_job();
        if($species){
            $this->dieWithStatus(200, $species['Species']['id']);
        } else {
            $this->dieWithStatus(204, 'No species modelling required.');
        }
    }

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

    /**
     * Called when the user requests remodelling for a species
     */
    public function request_model_rerun($species_id) {
        if(!User::canRequestRemodel(AuthComponent::user()))
            $this->dieWithStatus(403);

        $species = $this->Species->findById($species_id);
        if($species === False)
            $this->dieWithStatus(404, 'No species found with id = ' . $species_id);

        if($species['Species']['first_requested_remodel'] !== NULL)
            $this->dieWithStatus(200, 'Modelling already requested previously');

        $species['Species']['first_requested_remodel'] = date(DATE_ISO8601);
        $this->Species->save($species);
        $this->dieWithStatus(200, 'Request processed');
    }

    private function _canonicalName($species) {
        $longName = $species['Species']['common_name'] . " (" . $species['Species']['scientific_name'] . ")";
        $cleanName = preg_replace("[^A-Za-z0-9'-_., ()]", "_", $longName);
        return trim($cleanName);
    }

    /**
     * bounce the user's download request to the right URL to get the file
     */
    public function downloadOccurrences($species_id) {

        $species = $this->Species->findById($species_id);
        if($species === False)
            $this->dieWithStatus(404, 'No species found with id = ' . $species_id);

        $this->redirect(SpeciesController::DOWNLOAD_URL_PREFIX . $this->_canonicalName($species) . '/occurrences/latest-occurrences.zip');
//        $this->redirect(SpeciesController::DOWNLOAD_URL_PREFIX . $species_id . '/latest-occurrences.zip');
    }

    /**
     * bounce the user's download request to the right URL to get the file
     */
    public function downloadClimate($species_id) {

        $species = $this->Species->findById($species_id);
        if($species === False)
            $this->dieWithStatus(404, 'No species found with id = ' . $species_id);

        $this->redirect(SpeciesController::DOWNLOAD_URL_PREFIX . $this->_canonicalName($species) . '/climate-suitability/latest-climate-suitability.zip');
//        $this->redirect(SpeciesController::DOWNLOAD_URL_PREFIX . $species_id . '/latest-climate.zip');
    }

    private function _speciesToJson($species) {
        return array(
            'id' => $species['id'],
            'scientificName' => $species['scientific_name'],
            'commonName' => $species['common_name'],
            'numDirtyOccurrences' => $species['num_dirty_occurrences'],
            'canRequestRemodel' => (bool)($species['num_dirty_occurrences'] > 0 && $species['first_requested_remodel'] === null),
            'remodelStatus' => $this->_speciesRemodelStatusMessage($species),
            'label' => $species['common_name'].' - '.$species['scientific_name']
        );
    }

    private function _speciesRemodelStatusMessage($species) {
        if($species['num_dirty_occurrences'] <= 0)
            return 'Up to date';

        if($species['current_model_status'] !== null)
            return 'Remodelling running with status: ' . $species['current_model_status'];

        if($species['first_requested_remodel'] !== null)
            return 'Priority queued for remodelling';

        return 'Automatically queued for remodelling';
    }

    private function _next_job() {
        $species = $this->Species->find('first', array(
            'fields' => array('*', 'first_requested_remodel IS NULL AS is_null'),
            'conditions' => array(
                'OR' => array(
                    // Run any models that haven't started yet...
                    array(
                        'num_dirty_occurrences >' => 0,
                        'current_model_status' => null
                    ),
                    // Run old models again
                    array(
                        'num_dirty_occurrences >' => 0,
                        'current_model_queued_time <' => date(DATE_ISO8601, strtotime("-1 days"))
                    ),
                    // Run any models with a status, but no recorded queued time
                    // (these should never happen)
                    array(
                        'current_model_status <>' => null,
                        'current_model_queued_time' => null
                    )

                )
            ),
            'order' => array(
                'is_null' => 'ASC',
                'first_requested_remodel' => 'ASC',
                'num_dirty_occurrences' => 'DESC',
            )
        ));

        return $species;
    }
}
