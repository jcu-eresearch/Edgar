<?php
/**
 * GeolocationsBehavior provides geo location functions for models that have a series of locations associated with them.
 *
 * Expects Model's that use this behaviour to have a toLocationsArray method.
 * Each location must have at least a latitude and longitude.
 */
class GeolocationsBehavior extends ModelBehavior {

    const NON_CLUSTERED_FEATURE_RADIUS   = 8;     // pixels

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
    public function toGeoJSONArray(Model $Model, $bounds = array(), $cluster_type="dotradius" ) {

        include 'clustering/dotradius.php';
        include 'clustering/dotgrid.php';
        include 'clustering/squaregrid.php';

        $locations = $Model->getLocationsArray();
        $location_features = array();

        if ( $cluster_type == "dotradius" ) {
            // use the dotradius "clustering" method (it's not really clustering..)
            $location_features = get_features_dotradius($Model, $bounds);

        } elseif ( $cluster_type == "dotgrid" ) {
            // use dotgrid clustering
            $location_features = get_features_dotgrid($Model, $bounds);

        } elseif ( $cluster_type == "squaregrid" ) {
            // use dotgrid clustering
            $location_features = get_features_squaregrid($Model, $bounds);

        } else {
            // unrecognised clustering type, or clustering type == none
            foreach($locations as $location) {
                $longitude = $location['longitude'];
                $latitude = $location['latitude'];
                if ( GeolocationsBehavior::withinBounds($longitude, $latitude, $bounds) ) {
                    $location_features[] = array(
                        "type" => "Feature",
                        'properties' => array(
                            'title' => "Occurrence",
                            'description' => "<dl><dt>Latitude</dt><dd>$longitude</dd><dt>Longitude</dt><dd>$latitude</dd>",
                            'point_radius' => GeolocationsBehavior::NON_CLUSTERED_FEATURE_RADIUS
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
