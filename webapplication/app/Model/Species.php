<?php

// File: app/Model/Species.rb
class Species extends AppModel {
    public $name = 'Species';
    public $recursive = -1; //stops queries fetching all the occurrences

    // Define behaviours
    public $actsAs = array(
        'HPCQueueable' => array(),
        'Geolocations' => array()
    );

    // A Species has many occurrences.
    public $hasMany = array(
        'Occurrence' => array(
            'className' => 'Occurrence',
            'dependent' => true,
//            'order'     => 'rand()',
//            'limit'     => 10000
        )
    );

    // Return an array of locations
    // Needed for the Geolocations behaviour
    public function getLocationsArray() {
        $results = $this->getDataSource()->execute(
            'SELECT ST_X(location::geometry) as longitude, ST_Y(location::geometry) as latitude '.
            'FROM occurrences '.
            'WHERE species_id = ?',
            array(),
            array($this->data['Species']['id'])
        );
        return $results;
    }
}
