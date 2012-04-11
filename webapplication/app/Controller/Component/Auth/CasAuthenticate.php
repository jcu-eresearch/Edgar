<?php

App::import('Vendor', 'CAS/CAS');

class CasAuthenticate {
    private $_Collection = NULL;

    function __construct($collection, $settings) {
        $this->_Collection = $collection;

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
        return array('username' => phpCAS::getUser());
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
