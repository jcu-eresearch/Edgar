<?php
App::uses('AppController', 'Controller');
App::uses('User', 'Model');
App::uses('Species', 'Model');

/**
 * Vetting Controller
 *
 * @property Species $Species
 */
class VettingsController extends AppController {
    public $components = array('RequestHandler');
    public $helpers = array('Form', 'Html', 'Js', 'Time');

    // Don't allow a user to delete a vetting unless they are logged in.
    public function beforeFilter() {
        parent::beforeFilter();
        // Don't allow a vetting to be deleted unless the user is logged in
        $this->Auth->deny(array('delete'));
    }

    public function delete($vetting_id) {
        if ($this->request->is('get')) {
            throw new MethodNotAllowedException();
        }

        $vetting = $this->Vetting->find('first', array(
            'conditions' => array('Vetting.id' => $vetting_id)
        ));

        // If we can't find the vetting...
        if ( $vetting === false ) {
            // Couldn't find a vetting with that id
            throw new NotFoundException(__('Invalid vetting'));
        }

        $species = $vetting['Species'];

        // TODO - update the species to note the fact that it needs to have its vettings
        // re-applied.
        // Expectation: I expect that this will involve finding all the occurrences within the vetting,
        // and marking those as dirty.
        // The actual implementation of that is unknown atm, as currently the delete would happen inline.
        // i.e. in the user's request
        //
        // Question: hmmm... we store the number of dirty occurrences as simply a count. If we delete multiple vettings
        // and those overlap across an occurrence, i.e. an occurrence is coverered by multiple vettings, then the naive solution
        // of simply incrementing the dirty occurrences by the number of occurrences under a deleted vetting will not suffice.
        $deleted = $this->Vetting->delete($vetting_id);

        $json_object = array(
            'vetting_id' => $vetting_id,
            'deleted' => $deleted
        );

        $this->set('output', $json_object);
        $this->set('_serialize', 'output');
    }

}
