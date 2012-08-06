<?php
App::uses('AppController', 'Controller');
App::uses('User', 'Model');

class AdminController extends AppController {
    public $components = array('RequestHandler');
    public $helpers = array('Form', 'Html', 'Js', 'Time');

    public function beforeFilter() {
        parent::beforeFilter();
        if(!AuthComponent::user('is_admin')){
            $this->dieWithStatus(403);
        }
    }

    public function index() {
        $this->loadModel('Species');
        $dbo = $this->Species->getDataSource();
        $contentious = $this->Species->getDataSource()->execute(
                'SELECT * FROM species '.
                'WHERE num_contentious_occurrences > 0 '.
                'ORDER BY num_contentious_occurrences DESC '.
                'LIMIT 10'
            );

        $this->set('title_for_layout', 'Contentious Species');
        $this->set('contentious_species', $contentious->fetchAll(PDO::FETCH_ASSOC));
    }
}
