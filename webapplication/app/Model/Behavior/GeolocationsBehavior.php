<?php
/**
 * GeolocationsBehavior provides geo location functions for models that have a series of locations associated with them.
 *
 * Expects Model's that use this behaviour to have a toLocationsArray method.
 * Each location must have at least a latitude and longitude.
 */
class GeolocationsBehavior extends ModelBehavior {
	const GRID_RANGE_LONGITUDE = 80;    // how many longitude slices to make (cut into GRID_RANGE_LONGITUDE along the x axis)
	const GRID_RANGE_LATITUDE  = 40;    // how many latitude slices to make (cut into GRID_RANGE_LATITUDE along the y axis)
	const MIN_FEATURE_RADIUS   = 4;     // pixels

	/**
	 * Store the settings for this model.
	 */
	public function setup($Model, $config = array()) {
		$settings = $config;
		$this->settings[$Model->alias] = $settings;
	}

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
	public function toGeoJSONArray(Model $Model, $bounds = array(), $clustered=false ) {
		$locations = $Model->getLocationsArray();
		$location_features = array();

		if ( $clustered ) {
			// When the request is clustered, we require all bounds params to be set.
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

			// Use a grid cluster technique.
			// Cut the map up into a grid of GRID_RANGE_LONGITUDE x GRID_RANGE_LATITUDE
			// The grid is based on the bounds.
			// Transform all locations to the nearest grid position
			$min_longitude = $bounds['min_longitude'];
			$max_longitude = $bounds['max_longitude'];
			$min_latitude = $bounds['min_latitude'];
			$max_latitude = $bounds['max_latitude'];
			
			/*
				The following is a thought dump..
				It describes the clustering algorithm used.
				(assumes GRID_RANGE_LONGITUDE .nd GRID_RANGE_LATITUDE are 50)
					if min_lat 30 and max_lat 90
					max_lat - min_lat = 60
					60 is lat range.
					grid is 50
					60/50 is 1.2.
					Each grid point is 1.2 up/down
					A occurrence at 30 should be in array location 0    => ( 30 - 30 ) / 1.2
					An occurrence at 40 should be in array location 8   => ( 40 - 30 ) / 1.2
					An occurrence at 90 should be in array location 50  => ( 90 - 30 ) / 1.2
					transform is: ( occur_lat - min_lat ) / transform_lat
					transform_lat = ( max_lat - min_lat ) / range ( 1.2 in our example )
			*/
			$transform_longitude = ( $max_longitude - $min_longitude ) / GeolocationsBehavior::GRID_RANGE_LONGITUDE;
			$transform_latitude = ( $max_latitude - $min_latitude ) / GeolocationsBehavior::GRID_RANGE_LATITUDE;

			// Create a 2x2 array of the correct dimensions. Outside array is longitude. Inner array is latitude.
			$transformed_array = array_fill(
				0,
				GeolocationsBehavior::GRID_RANGE_LONGITUDE,
				array_fill(
					0, 
					GeolocationsBehavior::GRID_RANGE_LATITUDE,
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
				// using i, estimate the center of this grid coordinate (along the longitude axis)
				$original_longitude_approximation = ( ( $i * $transform_longitude) + $min_longitude + ( $transform_longitude / 2) );
				for ($j = 0; $j < sizeOf($transformed_array[$i]); $j++) {
					// j is the longitude indicator
					$locations_approximately_here       = $transformed_array[$i][$j];
					$locations_approximately_here_size  = sizeOf($locations_approximately_here);
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
						$point_radius = ( floor(log($locations_approximately_here_size) ) + GeolocationsBehavior::MIN_FEATURE_RADIUS );
						$location_features[] = array(
							"type" => "Feature",
							'properties' => array(
								'point_radius' => $point_radius,
								'title' => "".$locations_approximately_here_size." occurrences",
								'description' => "",
							),
							'geometry' => array(
								'type' => 'Point',
								'coordinates' => array($original_longitude_approximation, $original_latitude_approximation),
							),
						);
					}
				}
			}

		} else {
			foreach($locations as $location) {
				$longitude = $location['longitude'];
				$latitude = $location['latitude'];
				if ( GeolocationsBehavior::withinBounds($longitude, $latitude, $bounds) ) {
					$location_features[] = array(
						"type" => "Feature",
						'properties' => array(
							'point_radius' => 4
						),
						'geometry' => array(
							'type' => 'Point',
							'coordinates' => array($location['longitude'], $location['latitude']),
						),
					);
				}
			}
		}

		$geoObject = array(
			'type' => 'FeatureCollection',
			'features' => $location_features
		);
		return $geoObject;
	}

	public static function getLocationsWithinBounds($locations, $bounds = array()) {
		$returnArray = array();
		foreach($locations as $location) {
			$longitude = $location['longitude'];
			$latitude = $location['latitude'];
			if ( GeolocationsBehavior::withinBounds($longitude, $latitude, $bounds) ) {
				array_push($returnArray,$location);
			}
		}
		return $returnArray;
	}

	/**
	 * Returns true if the locations's latitude and longitude are within bounds.
	 *
	 * Only checks against bounds' existing keys.
	 * bounds' keys are:
	 *  min_latitude
	 *  max_latitude
	 *  min_longitude
	 *  max_longitude
	 *
	 * Bounds can be an empty array.
	 */
	public static function withinBounds($longitude, $latitude, $bounds = array()) {
		// > max lon
		if ( array_key_exists('max_longitude', $bounds) ) {
			if ( $longitude > $bounds['max_longitude'] ) {
				return false;
			}
		}

		// < max lon
		if ( array_key_exists('min_longitude', $bounds) ) {
			if ( $longitude < $bounds['min_longitude'] ) {
				return false;
			}
		}

		// > max lat
		if ( array_key_exists('max_latitude', $bounds) ) {
			if ( $latitude > $bounds['max_latitude'] ) {
				return false;
			}
		}

		// < min lat
		if ( array_key_exists('min_latitude', $bounds) ) {
			if ( $latitude < $bounds['min_latitude'] ) {
				return false;
			}
		}

		return true;

	}

}
