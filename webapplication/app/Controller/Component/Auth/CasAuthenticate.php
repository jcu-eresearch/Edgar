<?php

App::import('Vendor', 'CAS/CAS');

class CasAuthenticate {

    private $_settings = array();

    function __construct($collection, $settings) {
        $this->_settings = $settings;

        if(Configure::read('CAS.debug_log_enabled')){
            phpCAS::setDebug(TMP . 'phpCas.log.txt');
        }

        phpCAS::client(CAS_VERSION_2_0,
                       Configure::read('CAS.hostname'),
                       Configure::read('CAS.port'),
                       Configure::read('CAS.uri'));

        phpCAS::setCasServerCACert(Configure::read('CAS.cert_path'));
    }

    public function authenticate(CakeRequest $request, CakeResponse $response) {
        phpCAS::forceAuthentication();
        //$casInfo contains keys: firstname, lastname, userid, email
        $casInfo = phpCAS::getAttributes();

        //convert cas fields to user model fields
        $userInfo = array();
        foreach($this->_settings['fields'] as $casField => $userField){
            $userInfo[$userField] = $casInfo[$casField];
        }

        //find existing user in db using the model
        $userModelName = $this->_settings['userModel'];
        $keyField = $this->_settings['userModelKeyField'];
        $userModel = ClassRegistry::init($userModelName);
        $user = $userModel->find('first', array(
            'conditions' => array($keyField => $userInfo[$keyField])
        ));

        //if the user doesn't exist in the db, insert a new row
        if($user === false){
            $userModel->save(array($userModelName => $userInfo));
            $user = $userModel->find('first', array(
                'conditions' => array($keyField => $userInfo[$keyField])
            ));
            assert('$user !== false');
        }

        return $user[$userModelName];
    }

    public function getUser($request) {
        return FALSE;
    }

    public function logout($user) {
        if(phpCAS::isAuthenticated()){
            //Step 1. When the client clicks logout, this will run.
            //        phpCAS::logout will redirect the client to the CAS server.
            //        The CAS server will, in turn, redirect the client back to
            //        this same logout URL.
            //
            //        phpCAS will stop script execution after it sends the redirect
            //        header, which is a problem because CakePHP still thinks the
            //        user is logged in. See Step 2.
            $current_url = Router::url(null, true);
            phpCAS::logout(array('url' => $current_url));
        } else {
            //Step 2. This will run when the CAS server has redirected the client
            //        back to us. Do nothing in this method, then after this method
            //        returns CakePHP will do whatever is necessary to log the user
            //        out from its end (destroying the session or whatever).
        }
    }
}
