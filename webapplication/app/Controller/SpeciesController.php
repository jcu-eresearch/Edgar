<?php
App::uses('AppController', 'Controller');
App::uses('User', 'Model');

/**
 * Species Controller
 *
 * @property Species $Species
 */
class SpeciesController extends AppController {
    public $components = array('RequestHandler');
    public $helpers = array('Form', 'Html', 'Js', 'Time');

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
     * minimal_view method
     *
     * @param string $id
     * @return void
     */
    public function minimal_view($id = null) {
        $this->set('title_for_layout', 'Species - View');

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
        $this->Species->recursive = 1;
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
    }


    /**
     * Returns JSON for a jQuery UI autocomplete box
     */
    public function autocomplete() {
        //get what the user typed in
        $partial = $this->request->query['term'];

        //query db
        $matched_species = $this->Species->find('all', array(
            'conditions' => array('OR' => array(
                array('scientific_name LIKE' => '%'.$partial.'%'),
                array('common_name LIKE' => '%'.$partial.'%')
            )),
            'order' => array('common_name DESC')
        ));

        //convert $matched_species into json format expected by jquery ui
        foreach($matched_species as $key => $value){
            $species = $this->_speciesToJson($value['Species']);
            $matched_species[$key] = $species;
        }

        //render json
        $this->set('results', $matched_species);
        $this->set('_serialize', 'results');
    }

    /**
     * Return next species to run a modelling job for
     */
    public function next_job() {
        $species = $this->Species->find('first', array(
            'fields' => array('*', 'first_requested_remodel IS NULL AS is_null'),
            'order' => array(
                'is_null' => 'ASC',
                'first_requested_remodel' => 'ASC',
                'num_dirty_occurrences' => 'DESC'
            ),
            'conditions' => 'num_dirty_occurrences > 0'
        ));

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
        if($jobStatus === 'FINISHED_SUCCESS' || $jobStatus === 'FINISHED_FAILURE'){
            $occurrencesCleared = (int)$this->request->data('dirty_occurrences');
            $species['Species']['num_dirty_occurrences'] -= $occurrencesCleared;
            $species['Species']['remodel_status'] = null;
            $species['Species']['first_requested_remodel'] = null;
        } else {
            $jobStatusMsg = $this->request->data('job_status_message');
            $species['Species']['remodel_status'] = $jobStatusMsg;
        }

        $this->Species->save($species);
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

        if($species['remodel_status'] !== null)
            return 'Remodelling running with status: ' . $species['remodel_status'];

        if($species['first_requested_remodel'] !== null)
            return 'Priority queued for remodelling';

        return 'Automatically queued for remodelling';
    }
}
