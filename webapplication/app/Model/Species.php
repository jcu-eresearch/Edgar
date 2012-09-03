<?php

// File: app/Model/Species.rb
class Species extends AppModel {
    public $name = 'Species';
    public $recursive = -1; // stops queries fetching all the occurrences

    // Define behaviours this model exhibits
    public $actsAs = array(
        'HPCQueueable' => array(),
        'Geolocations' => array()
    );

    // A Species has many occurrences and vettings (dependent destory)
    public $hasMany = array(
        'Occurrence' => array(
            'className' => 'Occurrence',
            'dependent' => true,
        ),
        'Vetting' => array(
            'className' => 'Vetting',
            'dependent' => true,
        )
    );

    // Returns a PDOStatement of occurrence rows within the bounding box for this species
    public function occurrencesInBounds($bounds = null, $offset = 0, $limit = null) {
        $sql = 'SELECT sources.name as source_name, sources.url as source_url, source_id, source_classification, basis, date, uncertainty, classification, contentious, ST_X(location) as longitude, ST_Y(location) as latitude '.
               'FROM occurrences, sources '.
               'WHERE occurrences.source_id = sources.id AND species_id = ? ';

        $query_args = array();
        $query_args[] = $this->data['Species']['id'];

        if($bounds !== null){
            $bounds = sprintf("SetSRID('BOX(%.12F %.12F,%.12F %.12F)'::box2d,4326)",
                              $bounds['min_longitude'],
                              $bounds['min_latitude'],
                              $bounds['max_longitude'],
                              $bounds['max_latitude']);
            $sql .= 'AND location && ' . $bounds;
        }

        if ( !is_null($limit) && !is_null($offset) ) {
          $sql = $sql .
            'LIMIT ? ' .
            'OFFSET ? ';
            'ORDER BY species_id';

          $query_args[] = $limit;
          $query_args[] = $offset;
        }

        return $this->getDataSource()->execute(
            $sql,
            array(),
            $query_args
        );
    }

    // Marks an arbritrary species as needing vetting
    //
    // TODO -> consider updating to work from $this->data['Species']['id']
    public function markAsNeedingVetting($species_id){
        $this->getDataSource()->execute(
            'UPDATE species SET needs_vetting_since = NOW() '.
            'WHERE id = ? AND needs_vetting_since IS NULL',
            array(),
            array($species_id)
        );
    }

    // Returns the canonical name of the species
    public function canonicalName() {
        $longName = $this->data['Species']['common_name'] . " (" . $this->data['Species']['scientific_name'] . ")";
        $cleanName = preg_replace("[^A-Za-z0-9'-_., ()]", "_", $longName);
        return trim($cleanName);
    }

    // Returns a PDOStatement of clustered occurrence rows within the bounding box for this species
    // if $lat_lng_round_to_nearest_nth_fraction is null, don't round (simply group by)
    // limit and offset are only applied if both are set (not null)
    // Note: This function always groups by position (i.e. you can't get individual occurrences from this function)
    public function detailedClusteredOccurrencesInBounds($bounds, $lat_lng_round_to_nearest_nth_fraction = null, $offset=0, $limit=null) {

        // use postgis to set the bounding box
        $bounds = sprintf("SetSRID('BOX(%.12F %.12F,%.12F %.12F)'::box2d,4326)",
                          $bounds['min_longitude'],
                          $bounds['min_latitude'],
                          $bounds['max_longitude'],
                          $bounds['max_latitude']);

        $query_args = array();
        $sql = "";

        // if not rounding to nearest fraction...
        if ( is_null($lat_lng_round_to_nearest_nth_fraction) ) {
            $sql = $sql .
            "SELECT ".
              "CAST (ST_X(location) as numeric) as longitude, ".
              "CAST (ST_Y(location) as numeric) as latitude, ";

        // else - rounding to nearest nth of a fraction, so do some rounding maths on the lat/lng
        } else {
            $sql = $sql .
            "SELECT ".
              "( floor(CAST (ST_X(location) as numeric) * ?) / ? ) + (1.0 / ( 2.0 * ? ) ) as longitude, ".
              "( floor(CAST (ST_Y(location) as numeric) * ?) / ? ) + (1.0 / ( 2.0 * ? ) ) as latitude, ";

            // set appropriate query args
            $query_args[] = $lat_lng_round_to_nearest_nth_fraction;
            $query_args[] = $lat_lng_round_to_nearest_nth_fraction;
            $query_args[] = $lat_lng_round_to_nearest_nth_fraction;
            $query_args[] = $lat_lng_round_to_nearest_nth_fraction;
            $query_args[] = $lat_lng_round_to_nearest_nth_fraction;
            $query_args[] = $lat_lng_round_to_nearest_nth_fraction;
        }

        // get sums of classification counts
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
            'GROUP BY longitude, latitude ';
        $query_args[] = $this->data['Species']['id'];

        // if both limit and offset are set,
        // then apply limit/offset and order by position
        if ( !is_null($limit) && !is_null($offset) ) {
          $sql = $sql .
            'LIMIT ? ' .
            'OFFSET ? ';
            'ORDER BY longitude, latitude ';

          $query_args[] = $limit;
          $query_args[] = $offset;
        }

        // execute the sql query we've been building
        return $this->getDataSource()->execute(
            $sql,
            array(),
            $query_args
        );
    }
}
