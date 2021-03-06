<?php
/**
 * Application level Controller
 *
 * This file is application-wide controller file. You can put all
 * application-wide controller-related methods here.
 *
 * PHP 5
 *
 * CakePHP(tm) : Rapid Development Framework (http://cakephp.org)
 * Copyright 2005-2012, Cake Software Foundation, Inc. (http://cakefoundation.org)
 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright 2005-2012, Cake Software Foundation, Inc. (http://cakefoundation.org)
 * @link          http://cakephp.org CakePHP(tm) Project
 * @package       app.Controller
 * @since         CakePHP(tm) v 0.2.9
 * @license       MIT License (http://www.opensource.org/licenses/mit-license.php)
 */

App::uses('Controller', 'Controller');

/**
 * Application Controller
 *
 * Add your application-wide methods in the class below, your controllers
 * will inherit them.
 *
 * @package       app.Controller
 * @link http://book.cakephp.org/2.0/en/controllers.html#the-app-controller
 */
class AppController extends Controller {
    public $components = array(
        'Session',
        'Auth' => array(
            'loginRedirect' => array('controller' => 'species', 'action' => 'map'),
            'logoutRedirect' => array('controller' => 'species', 'action' => 'map')
        )
    );

    public function beforeFilter() {
        parent::beforeFilter();

        $this->Auth->authenticate = array(
            'Cas' => array(
                'userModel' => 'User',
                'userModelKeyField' => 'email',
                'fields' => array(
                    'email' => 'email',
                    'firstname' => 'fname',
                    'lastname' => 'lname'
                )
            ),
            'Form' => array('userModel' => 'User')
        );
        $this->Auth->allow();
    }

    public function dieWithStatus($statusCode, $msg = null) {
        $this->response->statusCode($statusCode);
        if($msg){
            $this->response->body($msg);
        } else {
            $statusMsg = $this->httpCodes($statusCode);
            $this->response->body($statusCode . ' - ' . $statusMsg[$statusCode]);
        }
        $this->response->send();
        exit();
    }
}
