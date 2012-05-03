<?php

App::uses('AppModel', 'Model');

class User extends AppModel {
    public $name = 'User';

    static public function canRequestRemodel($user) {
        if($user){
            return (bool)$user['can_rate'];
        } else {
            return false;
        }
    }
}
