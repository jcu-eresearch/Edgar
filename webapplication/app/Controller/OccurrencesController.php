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

    /**
     * add method
     *
     * @return void
     */
    public function add() {
        if ($this->request->is('post')) {
            $this->Occurrence->create();
            if ($this->Occurrence->save($this->request->data)) {
                $this->Session->setFlash(__('The occurrence has been saved'));
                $this->redirect(array('action' => 'index'));
            } else {
                $this->Session->setFlash(__('The occurrence could not be saved. Please, try again.'));
            }
        }

        $species = NULL;
        if (array_key_exists('species_id', $this->request->query)) {
            $species_id = $this->request->query['species_id'];
            $species = $this->Occurrence->Species->find('list', array('conditions' => array('id' => $species_id)));

            // If we coudln't find any species with that id.
            if (empty($species)) {
                throw new NotFoundException(__('Invalid species_id'));
            }
        } else {
            $species = $this->Occurrence->Species->find('list');
        }
        $this->set(compact('species'));
    }

    /**
     * edit method
     *
     * @param string $id
     * @return void
     */
    public function edit($id = null) {
        $this->Occurrence->id = $id;
        if (!$this->Occurrence->exists()) {
            throw new NotFoundException(__('Invalid occurrence'));
        }
        if ($this->request->is('post') || $this->request->is('put')) {
            if ($this->Occurrence->save($this->request->data)) {
                $this->Session->setFlash(__('The occurrence has been saved'));
                $this->redirect(array('action' => 'index'));
            } else {
                $this->Session->setFlash(__('The occurrence could not be saved. Please, try again.'));
            }
        } else {
            $this->request->data = $this->Occurrence->read(null, $id);
        }
        $species = $this->Occurrence->Species->find('list');
        $this->set(compact('species'));
    }

    /**
     * delete method
     *
     * @param string $id
     * @return void
     */
    public function delete($id = null) {
        if (!$this->request->is('post')) {
            throw new MethodNotAllowedException();
        }
        $this->Occurrence->id = $id;
        if (!$this->Occurrence->exists()) {
            throw new NotFoundException(__('Invalid occurrence'));
        }
        if ($this->Occurrence->delete()) {
            $this->Session->setFlash(__('Occurrence deleted'));
            $this->redirect(array('action' => 'index'));
        }
        $this->Session->setFlash(__('Occurrence was not deleted'));
        $this->redirect(array('action' => 'index'));
    }
}
