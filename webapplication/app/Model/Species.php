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
        ),
        'Vetting' => array(
            'className' => 'Vetting',
            'dependent' => true,
//            'order'     => 'rand()',
//            'limit'     => 10000
        )
    );

    // Returns a PDOStatement of occurrence rows within the bounding box for this species
    public function occurrencesInBounds($bounds=null) {
        $sql = 'SELECT source_classification, classification, contentious, ST_X(location) as longitude, ST_Y(location) as latitude '.
               'FROM occurrences '.
               'WHERE species_id = ? ';

        if($bounds !== null){
            $bounds = sprintf("SetSRID('BOX(%.12F %.12F,%.12F %.12F)'::box2d,4326)",
                              $bounds['min_longitude'],
                              $bounds['min_latitude'],
                              $bounds['max_longitude'],
                              $bounds['max_latitude']);
            $sql .= 'AND location && ' . $bounds;
        }

        return $this->getDataSource()->execute(
            $sql,
            array(),
            array($this->data['Species']['id'])
        );
    }

    public function markAsNeedingVetting($species_id){
        $this->getDataSource()->execute(
            'UPDATE species SET needs_vetting_since = NOW() '.
            'WHERE id = ? AND needs_vetting_since IS NULL',
            array(),
            array($species_id)
        );
    }
}
