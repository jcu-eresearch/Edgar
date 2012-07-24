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

    // Returns a PDOStatement of clustered occurrence rows within the bounding box for this species
    public function detailedClusteredOccurrencesInBounds($bounds, $lat_lng_round_to_x_decimal_places = 0) {
        $bounds = sprintf("SetSRID('BOX(%.12F %.12F,%.12F %.12F)'::box2d,4326)",
                          $bounds['min_longitude'],
                          $bounds['min_latitude'],
                          $bounds['max_longitude'],
                          $bounds['max_latitude']);

        $sql = "".
            "SELECT ".
              "round(CAST (ST_X(location) as numeric), ?) as longitude, ".
              "round(CAST (ST_Y(location) as numeric), ?) as latitude, ".
              "sum(case when classification = 'unknown' then 1 else 0 end) as unknown_count, ".
              "sum(case when classification = 'invalid' then 1 else 0 end) as invalid_count, ".
              "sum(case when classification = 'historic' then 1 else 0 end) as historic_count, ".
              "sum(case when classification = 'vagrant' then 1 else 0 end) as vagrant_count, ".
              "sum(case when classification = 'irruptive' then 1 else 0 end) as irruptive_count, ".
              "sum(case when classification = 'non-breeding' then 1 else 0 end) as non_breeding_count, ".
              "sum(case when classification = 'introduced non-breeding' then 1 else 0 end) as introduced_non_breeding_count, ".
              "sum(case when classification = 'breeding' then 1 else 0 end) as breeding_count, ".
              "sum(case when classification = 'introduced breeding' then 1 else 0 end) as introduced_breeding_count, ".
              "COUNT(*) as total_classification_count ".
            'FROM occurrences '.
            'WHERE '.
              'species_id = ? '.
              'AND location && ' . $bounds .' '.
            'GROUP BY longitude, latitude';

        return $this->getDataSource()->execute(
            $sql,
            array(),
            array($lat_lng_round_to_x_decimal_places, $lat_lng_round_to_x_decimal_places, $this->data['Species']['id'])
        );
    }
}
