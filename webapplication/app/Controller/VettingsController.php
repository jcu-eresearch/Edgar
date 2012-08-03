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

    // Don't allow any interaction with the vetting controller unless logged in.
    public function beforeFilter() {
        parent::beforeFilter();
        $this->Auth->deny();
    }

    public function view($vetting_id) {
        $vetting = $this->Vetting->find('first', array(
            'conditions' => array('Vetting.id' => $vetting_id)
        ));

        $json_object = $vetting['Vetting'];

        $this->set('output', $json_object);
        $this->set('_serialize', 'output');
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

        $logged_in_user = AuthComponent::user();
        if ( $vetting['Vetting']['user_id'] !== $logged_in_user['id'] ) {
            throw new ForbiddenException("You aren't the owner of the vetting");
        }

        if ( $vetting['Vetting']['deleted'] === null ) {
            $vetting['Vetting']['deleted'] = date(DATE_ISO8601);
            unset($vetting['Vetting']['modified']);
            $this->Vetting->save($vetting);
            $this->Vetting->Species->markAsNeedingVetting($vetting['Vetting']['species_id']);
        }

        $json_object = $vetting['Vetting'];

        $this->set('output', $json_object);
        $this->set('_serialize', 'output');
    }

    public function ignore($vetting_id) {
        if(!AuthComponent::user('is_admin'))
            $this->dieWithStatus(403);

        $vetting = $this->Vetting->find('first', array(
            'conditions' => array('Vetting.id' => $vetting_id)
        ));

        if($vetting === false)
            $this->dieWithStatus(404);

        if(!$vetting['Vetting']['ignored']){
            $vetting['Vetting']['ignored'] = date(DATE_ISO8601);
            $vetting['Vetting']['modified'] = $vetting['Vetting']['ignored'];
            $this->Vetting->save($vetting);
            $this->Vetting->Species->markAsNeedingVetting($vetting['Vetting']['species_id']);
        }

        $json_object = $vetting['Vetting'];
        $this->set('output', $json_object);
        $this->set('_serialize', 'output');
    }

}
