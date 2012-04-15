<?php

// File: app/Model/Species.rb
class Species extends AppModel {
    public $name = 'Species';

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
        )
    );

    // Return an array of locations
    // Needed for the Geolocations behaviour
    public function getLocationsArray() {
        return $this->data['Occurrence'];
    }
}
