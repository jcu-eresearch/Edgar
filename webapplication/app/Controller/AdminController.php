<?php
App::uses('AppController', 'Controller');
App::uses('User', 'Model');

class AdminController extends AppController {
    public $components = array('RequestHandler');
    public $helpers = array('Form', 'Html', 'Js', 'Time');

    // ensure that the user is an admin before letting user
    // access admin controller
    // 403 if user not logged in as admin
    public function beforeFilter() {
        // don't forget to run 'super'
        parent::beforeFilter();
        if(!AuthComponent::user('is_admin')){
            $this->dieWithStatus(403);
        }
    }

    // display the 10 most contentious species
    // (based on the number of contentious occurrences)
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
