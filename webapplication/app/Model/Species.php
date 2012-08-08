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

    // if $lat_lng_round_to_nearest_nth_fraction is null, don't round (simply group by).
    public function detailedClusteredOccurrencesInBounds($bounds, $lat_lng_round_to_nearest_nth_fraction = null) {
        $bounds = sprintf("SetSRID('BOX(%.12F %.12F,%.12F %.12F)'::box2d,4326)",
                          $bounds['min_longitude'],
                          $bounds['min_latitude'],
                          $bounds['max_longitude'],
                          $bounds['max_latitude']);

        $query_args = array();
        $sql = "";

        if ( is_null($lat_lng_round_to_nearest_nth_fraction) ) {
            $sql = $sql .
            "SELECT ".
              "CAST (ST_X(location) as numeric) as longitude, ".
              "CAST (ST_Y(location) as numeric) as latitude, ";
        } else {
            $sql = $sql .
            "SELECT ".
              "( floor(CAST (ST_X(location) as numeric) * ?) / ? ) + (1.0 / ( 2.0 * ? ) ) as longitude, ".
              "( floor(CAST (ST_Y(location) as numeric) * ?) / ? ) + (1.0 / ( 2.0 * ? ) ) as latitude, ";

            $query_args[] = $lat_lng_round_to_nearest_nth_fraction;
            $query_args[] = $lat_lng_round_to_nearest_nth_fraction;
            $query_args[] = $lat_lng_round_to_nearest_nth_fraction;
            $query_args[] = $lat_lng_round_to_nearest_nth_fraction;
            $query_args[] = $lat_lng_round_to_nearest_nth_fraction;
            $query_args[] = $lat_lng_round_to_nearest_nth_fraction;
        }
        $sql = $sql .
              "sum(case when classification = 'unknown' then 1 else 0 end) as unknown_count, ".
              "sum(case when classification = 'invalid' then 1 else 0 end) as invalid_count, ".
              "sum(case when classification = 'historic' then 1 else 0 end) as historic_count, ".
              "sum(case when classification = 'vagrant' then 1 else 0 end) as vagrant_count, ".
              "sum(case when classification = 'irruptive' then 1 else 0 end) as irruptive_count, ".
              "sum(case when classification = 'core' then 1 else 0 end) as core_count, ".
              "sum(case when classification = 'introduced' then 1 else 0 end) as introduced_count, ".

              "sum(case when classification = 'unknown' and contentious = true then 1 else 0 end) as contentious_unknown_count, ".
              "sum(case when classification = 'invalid' and contentious = true then 1 else 0 end) as contentious_invalid_count, ".
              "sum(case when classification = 'historic' and contentious = true then 1 else 0 end) as contentious_historic_count, ".
              "sum(case when classification = 'vagrant' and contentious = true then 1 else 0 end) as contentious_vagrant_count, ".
              "sum(case when classification = 'irruptive' and contentious = true then 1 else 0 end) as contentious_irruptive_count, ".
              "sum(case when classification = 'core' and contentious = true then 1 else 0 end) as contentious_core_count, ".
              "sum(case when classification = 'introduced' and contentious = true then 1 else 0 end) as contentious_introduced_count, ".

              "sum(case when contentious = true then 1 else 0 end) as contentious_count, ".

              "COUNT(*) as total_occurrences ".
            'FROM occurrences '.
            'WHERE '.
              'species_id = ? '.
              'AND location && ' . $bounds .' '.
            'GROUP BY longitude, latitude';

        $query_args[] = $this->data['Species']['id'];

        return $this->getDataSource()->execute(
            $sql,
            array(),
            $query_args
        );
    }
}
