<?php
    /**
     * Dump the object to a geoJSONArray
     *
     * If bounds are provided, only show locations within the provided bounds 
     * bounds is an array of min_latitude, max_latitude, min_longitude, max_longitude
     *
     * If clustered is true, then bounds are required.
     *
     * Clustered will return features in clusters, rather than a single feature per location.
     */
function get_features_squaregrid(Model $Model, $bounds ) {

    $MAX_SQUARES_LONG = 90;    // how many longitude slices to make, at most
    $SIDE_LENGTH_OPTIONS = array(8, 4, 2, 1, 0.5, 0.25, 0.125, 0.0625, 0.03125);  // four per parent
//    $SIDE_LENGTH_OPTIONS = array(9, 3, 1, 0.333333333333, 0.111111111111, 0.037037037037);  // nine per parent

    $uncluster_at = 0;
    $uncluster_at = 1;

    $single_obs_radius = 4; // pixels

    $location_features = array();

    // The grid is based on the bounds.
    $min_long = $bounds['min_longitude'];
    $max_long = $bounds['max_longitude'];
    $min_lat = $bounds['min_latitude'];
    $max_lat = $bounds['max_latitude'];

    $long_range = $max_long - $min_long;
    $lat_range = $max_lat - $min_lat;

    $side = $SIDE_LENGTH_OPTIONS[0];
    // find the best size for side of square, based on our options
    foreach($SIDE_LENGTH_OPTIONS as $candidate_side) {
        // starting at the high end, test candidates; if a candidate wouldn't make to many squares, it's accepted
        if (($long_range / $candidate_side) < $MAX_SQUARES_LONG) {
            $side = $candidate_side;
        }
    }
    // $side is now the smallest side that makes less than $MAX_SQUARES_LONG squares longitudinally

    // now, our squares, whatever size they are, should be aligned to (0,0).  So if you chose
    // 8 degree squares, the grid squares should have be at 0, 8, 16, etc (not 1, 9, 17...).  To 
    // make this work we have to re-adjust the lat and long starting points to be multiples of 
    // the chosen side length.
    $squares_longitudinally = ceil($long_range / $side) + 1;
    $min_long = floor($min_long / $side) * $side;
    $max_long = $min_long + ($side * $squares_longitudinally);
    $long_range = $max_long - $min_long;

    $squares_latitudinally = ceil($lat_range / $side) + 1;
    $min_lat = floor($min_lat / $side) * $side;
    $max_lat = $min_lat + ($side * $squares_latitudinally);
    $lat_range = $max_lat - $min_lat;

    // Create a 2x2 array of the correct dimensions. Outside array is longitude. Inner array is latitude.
    $transformed_array = array_fill(
        0,
        $squares_longitudinally,
        array_fill(
            0, 
            $squares_latitudinally,
            array()
        )
    );

    // Iterate over the locations (pass instance location by reference)
    foreach($Model->occurrencesInBounds($bounds) as $location) {
        $longitude = $location['longitude'];
        $latitude = $location['latitude'];

        // transform the latitude and longitude into our grid co-ordinates
        $transformed_longitude = floor( ( $longitude - $min_long ) / $side );
        $transformed_latitude  = floor( ( $latitude - $min_lat ) / $side );

        // Look up the grid array for this transformed location
        $this_locations_array = &$transformed_array[$transformed_longitude][$transformed_latitude];

        // Append the location into the grid's array
        $this_locations_array[] = $location;
    }

    // just to be fancy, work out the ordered list of cluster sizes
    $sizes = array();

    // Iterate over our transformed array (our grid array)
    for ($i = 0; $i < sizeOf($transformed_array); $i++) {

        // i is the longitude indicator
        $long_min = (    $i    * $side) + $min_long;
        $long_max = ( ($i + 1) * $side) + $min_long;

        for ($j = 0; $j < sizeOf($transformed_array[$i]); $j++) {

            // j is the longitude indicator
            $locations_approximately_here       = $transformed_array[$i][$j];
            $locations_approximately_here_size  = sizeOf($locations_approximately_here);
            if ($locations_approximately_here_size > $uncluster_at) {

                $sizes[] = $locations_approximately_here_size;

                $lat_min = (    $j    * $side) + $min_lat;
                $lat_max = ( ($j + 1) * $side) + $min_lat;

                $coords = array(
                    array($long_min, $lat_min),
                    array($long_min, $lat_max),
                    array($long_max, $lat_max),
                    array($long_max, $lat_min),
                    array($long_min, $lat_min)
                );

                $location_features[] = array(
                    "type" => "Feature",
                    'properties' => array(
                        'occurrence_type' => 'squaregrid',
                        'cluster_size' => 'large',
                        'title' => "".$locations_approximately_here_size." occurrences",
                        'description' => "",
                        'label' => $locations_approximately_here_size,
                    ),
                    'geometry' => array(
                        'type' => 'Polygon',
                        'coordinates' => array($coords),
                    ),
                );
            } else {
                for ($loc = sizeOf($locations_approximately_here)-1; $loc >= 0; $loc--) {
                    $long = $locations_approximately_here[$loc]['longitude'];
                    $lat = $locations_approximately_here[$loc]['latitude'];
                    $location_features[] = array(
                        "type" => "Feature",
                        'properties' => array(
                            'title' => "Occurrence",
                            'occurrence_type' => 'dotradius',
                            'description' => "<dl><dt>Latitude</dt><dd>$lat</dd><dt>Longitude</dt><dd>$long</dd>",
                            'point_radius' => $single_obs_radius,
                        ),
                        'geometry' => array(
                            'type' => 'Point',
                            'coordinates' => array($long, $lat),
                        ),
                    );
                }
            }
        }
    }

    // show large/medium/small cluster sizes
    sort($sizes);
    $maxsmall = $sizes[floor(sizeOf($sizes) / 3)];
    $maxmedium = $sizes[floor(sizeOf($sizes) / 3 * 2)];

    for ($i = sizeOf($location_features)-1; $i >= 0; $i--) {
        if ($location_features[$i]['properties']['occurrence_type'] == 'squaregrid') {
            $size = $location_features[$i]['properties']['label'];
            if ($size < $maxsmall) {
                $location_features[$i]['properties']['cluster_size'] = 'small';
            } elseif ($size < $maxmedium) {
                $location_features[$i]['properties']['cluster_size'] = 'medium';
            } else {
                $location_features[$i]['properties']['cluster_size'] = 'large';
            }
        }
    }

    // woop we're done!
    return $location_features;

}

