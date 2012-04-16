<?php
App::uses('AppController', 'Controller');
/**
 * Species Controller
 *
 * @property Species $Species
 */
class SpeciesController extends AppController {
    public $components = array('RequestHandler');

    /**
     * index method
     *
     * @return void
     */
    public function index() {
        $this->set('title_for_layout', 'Species - Index');

        $this->Species->recursive = 0;
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
//        $clustered = true;
//        if ( array_key_exists('clustered', $this->request->query) ) {
//            $clustered = $this->request->query['clustered'];
//        }
        $clustered = false;

        $this->set('geo_object', $this->Species->toGeoJSONArray($bbox, $clustered));

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

        $this->Species->recursive = 0;

        $this->Species->id = $id;
        if (!$this->Species->exists()) {
            throw new NotFoundException(__('Invalid species'));
        }

        $this->set('species', $this->Species->read(null, $id));
    }

}
