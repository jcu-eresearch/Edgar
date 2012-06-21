<?php

// File: app/Model/Vetting.rb
class Vetting extends AppModel {
    public $name = 'Vetting';

    public $belongsTo = array(
        'User' => array(
            'className' => 'User',
            'foreignKey' => 'user_id'
        ),
        'Species' => array(
            'className' => 'Species',
            'foreignKey' => 'species_id'
        )
    );
}
