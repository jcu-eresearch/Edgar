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
function get_features_squaregrid(Model $Model, $bounds = array() ) {

    $MAX_LONGITUDE_GRID = 80;    // how many longitude slices to make, at most
    $SQUARE_SIDE_OPTIONS = array(16, 8, 4, 2, 1, 0.5, 0.25, 0.125, 0.0625, 0.03125);

    $locations = $Model->getLocationsArray();
    $location_features = array();

    if ( !array_key_exists('min_latitude', $bounds) ) {
        throw new BadRequestException(__('min_latitude bounds required when request is clustered.'));
    }
    if ( !array_key_exists('max_latitude', $bounds) ) {
        throw new BadRequestException(__('max_latitude bounds required when request is clustered.'));
    }
    if ( !array_key_exists('min_longitude', $bounds) ) {
        throw new BadRequestException(__('min_longitude bounds required when request is clustered.'));
    }
    if ( !array_key_exists('max_longitude', $bounds) ) {
        throw new BadRequestException(__('max_longitude bounds required when request is clustered.'));
    }

    // The grid is based on the bounds.
    $min_longitude = $bounds['min_longitude'];
    $max_longitude = $bounds['max_longitude'];
    $min_latitude = $bounds['min_latitude'];
    $max_latitude = $bounds['max_latitude'];

    $long_range = $max_longitude - $min_longitude;

    $side = $SQUARE_SIDE_OPTIONS[0];
    // find the best size for side of square, based on our options
    foreach($SQUARE_SIDE_OPTIONS as $candidate_side) {
        if (($long_range / $candidate_side) < $MAX_LONGITUDE_GRID) {
            $side = $candidate_side;
        }
    }

    $transform_longitude = $side;
    $transform_latitude = $side; // make them "square"

    $GRID_RANGE_LONGITUDE = (( $max_longitude - $min_longitude ) / $transform_longitude) + 1;
    $GRID_RANGE_LATITUDE = (( $max_latitude - $min_latitude ) / $transform_latitude) + 1;

    // Create a 2x2 array of the correct dimensions. Outside array is longitude. Inner array is latitude.
    $transformed_array = array_fill(
        0,
        $GRID_RANGE_LONGITUDE,
        array_fill(
            0, 
            $GRID_RANGE_LATITUDE,
            array()
        )
    );

    // Iterate over the locations (pass instance location by reference)
    foreach($locations as $location) {
        $longitude = $location['longitude'];
        $latitude = $location['latitude'];
        // If the location is within the bounds,
        // then place the location's id within the transformed array at the transformed grid location
        if ( GeolocationsBehavior::withinBounds($longitude, $latitude, $bounds) ) {
            // transform the latitude and longitude into our grid co-ordinates
            $transformed_longitude = floor( ( $longitude - $min_longitude ) / $transform_longitude );
            $transformed_latitude  = floor( ( $latitude - $min_latitude ) / $transform_latitude );

            // Look up the grid array for this transformed location
            $this_locations_array = &$transformed_array[$transformed_longitude][$transformed_latitude];

            // Append the location's id into the grid's array
            $this_locations_array[] = $location['id'];
        }
    }

    // Iterate over our transformed array (our grid array)
    for ($i = 0; $i < sizeOf($transformed_array); $i++) {

        // i is the longitude indicator
        $long_min = (    $i    * $transform_longitude) + $min_longitude;
        $long_max = ( ($i + 1) * $transform_longitude) + $min_longitude;

        for ($j = 0; $j < sizeOf($transformed_array[$i]); $j++) {

            // j is the longitude indicator
            $locations_approximately_here       = $transformed_array[$i][$j];
            $locations_approximately_here_size  = sizeOf($locations_approximately_here);
            if ($locations_approximately_here_size > 0) {
                // using j, estimate the center of this grid coordinate (along the latitude axis)
                $original_latitude_approximation  = ( ( $j * $transform_latitude) + $min_latitude + ( $transform_latitude / 2 ));

                $lat_min = (    $j    * $transform_latitude) + $min_latitude;
                $lat_max = ( ($j + 1) * $transform_latitude) + $min_latitude;
                
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
                        'title' => "".$locations_approximately_here_size." occurrences",
                        'description' => "",
                    ),
                    'geometry' => array(
                        'type' => 'Polygon',
                        'coordinates' => array($coords),
                    ),
                );
            }
        }
    }

    return $location_features;

}

