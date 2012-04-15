<?php
App::uses('AppController', 'Controller');
/**
 * Occurrences Controller
 *
 * @property Occurrence $Occurrence
 */
class OccurrencesController extends AppController {
    public $components = array('RequestHandler');


    /**
     * index method
     *
     * @return void
     */
    public function index() {
        $this->Occurrence->recursive = 0;
        $this->set('occurrences', $this->paginate());

        // Specify the output for the json views.
        $this->set('_serialize', 'occurrences');
    }

    /**
     * view method
     *
     * @param string $id
     * @return void
     */
    public function view($id = null) {
        $this->Occurrence->id = $id;
        if (!$this->Occurrence->exists()) {
            throw new NotFoundException(__('Invalid occurrence'));
        }
        $this->set('occurrence', $this->Occurrence->read(null, $id));
    }

}
