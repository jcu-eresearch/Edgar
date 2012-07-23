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
function get_features_dotgrid(Model $Model, $bounds ) {

    $GRID_RANGE_LONGITUDE = 120;    // how many longitude slices to make (cut into GRID_RANGE_LONGITUDE along the x axis)
    $MIN_FEATURE_RADIUS   = 3;     // pixels

    $location_features = array();

    // The grid is based on the bounds.
    $min_longitude = $bounds['min_longitude'];
    $max_longitude = $bounds['max_longitude'];
    $min_latitude = $bounds['min_latitude'];
    $max_latitude = $bounds['max_latitude'];

    /*
        The following is a thought dump..
        It describes the clustering algorithm used.
        (assumes GRID_RANGE_LONGITUDE and GRID_RANGE_LATITUDE are 50)
            if min_lat 30 and max_lat 90
            max_lat - min_lat = 60
            60 is lat range.
            grid is 50
            60/50 is 1.2.
            Each grid point is 1.2 up/down
            An occurrence at 30 should be in array location 0   => ( 30 - 30 ) / 1.2
            An occurrence at 40 should be in array location 8   => ( 40 - 30 ) / 1.2
            An occurrence at 90 should be in array location 50  => ( 90 - 30 ) / 1.2
            transform is: ( occur_lat - min_lat ) / transform_lat
            transform_lat = ( max_lat - min_lat ) / range ( 1.2 in our example )
    */

    $transform_longitude = ( $max_longitude - $min_longitude ) / $GRID_RANGE_LONGITUDE;
    $transform_latitude = $transform_longitude; // actually, make them "square"

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
    foreach($Model->occurrencesInBounds($bounds) as $location) {
        $longitude = $location['longitude'];
        $latitude = $location['latitude'];

        // transform the latitude and longitude into our grid co-ordinates
        $transformed_longitude = floor( ( $longitude - $min_longitude ) / $transform_longitude );
        $transformed_latitude  = floor( ( $latitude - $min_latitude ) / $transform_latitude );

        // Look up the grid array for this transformed location
        $this_locations_array = &$transformed_array[$transformed_longitude][$transformed_latitude];

        // Append the location's id into the grid's array
        $this_locations_array[] = $location['id'];
    }

    // Iterate over our transformed array (our grid array)
    for ($i = 0; $i < sizeOf($transformed_array); $i++) {
        // i is the longitude indicator
        // using i, estimate the center of this grid coordinate (along the longitude axis)
        $original_longitude_approximation = ( ( $i * $transform_longitude) + $min_longitude + ( $transform_longitude / 2) );
        $current_min_longitude_range = ( $i * $transform_longitude ) + $min_longitude;
        $current_max_longitude_range = ( $i * $transform_longitude ) + $transform_longitude + $min_longitude;

        for ($j = 0; $j < sizeOf($transformed_array[$i]); $j++) {
            // j is the longitude indicator
            $locations_approximately_here       = $transformed_array[$i][$j];
            $locations_approximately_here_size  = sizeOf($locations_approximately_here);

            $current_min_latitude_range  = ( $j * $transform_latitude ) + $min_latitude;
            $current_max_latitude_range  = ( $j * $transform_latitude ) + $transform_latitude + $min_latitude;

            if ($locations_approximately_here_size > 0) {
                // using j, estimate the center of this grid coordinate (along the latitude axis)
                $original_latitude_approximation  = ( ( $j * $transform_latitude) + $min_latitude + ( $transform_latitude / 2 ));
                // Using log (with floor), determine the size of the clustered feature.
                // 1-9       items = 0 + MIN_FEATURE_RADIUS
                // 10-99     items = 1 + MIN_FEATURE_RADIUS
                // 100-999   items = 2 + MIN_FEATURE_RADIUS
                // 1000-9999 items = 3 + MIN_FEATURE_RADIUS
                // etc.
                // Note: we subtract 1 as MIN_FEATURE_RADIUS should be correct for a cluster of 1

                // Create a well-formatted GeoJSON array for this cluster, and append it to our location_features array
                $point_radius = ( floor(log($locations_approximately_here_size, 2) ) + $MIN_FEATURE_RADIUS );


                $location_features[] = array(
                    "type" => "Feature",
                    'properties' => array(
                        'point_radius' => $point_radius,
                        'occurrence_type' => 'dotgrid',
                        'title' => "".$locations_approximately_here_size." occurrences",
                        'description' => "",
                        'min_latitude_range'  => $current_min_latitude_range,
                        'max_latitude_range'  => $current_max_latitude_range,
                        'min_longitude_range' => $current_min_longitude_range,
                        'max_longitude_range' => $current_max_longitude_range,
                    ),
                    'geometry' => array(
                        'type' => 'Point',
                        'coordinates' => array($original_longitude_approximation, $original_latitude_approximation),
                    ),
                );

            }
        }
    }

    return $location_features;

}

