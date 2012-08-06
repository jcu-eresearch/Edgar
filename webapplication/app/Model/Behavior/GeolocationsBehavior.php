<?php
/**
 * GeolocationsBehavior provides geo location functions for models that have a series of locations associated with them.
 *
 * Expects Model's that use this behaviour to have a toLocationsArray method.
 * Each location must have at least a latitude and longitude.
 */
class GeolocationsBehavior extends ModelBehavior {

    const NON_CLUSTERED_FEATURE_RADIUS   = 6;     // pixels
    const CLUSTERED_FEATURE_RADIUS       = 8;     // pixels
    const MIN_FEATURE_RADIUS = 3;                 // pixels

    // Draw a vetting bbox with a lat and lng of at least +/- this many degrees from
    // the occurrence.
    const MIN_VETTING_LAT_LNG_RANGE = 0.0005;

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
    public function toGeoJSONArray(Model $Model, $bounds = null, $cluster_type="dotradius" ) {

        include 'clustering/dotradius.php';
        include 'clustering/dotgrid.php';
        include 'clustering/dotgriddetail.php';
        include 'clustering/dotgridtrump.php';
        include 'clustering/squaregrid.php';

        $location_features = array();

        if ( $cluster_type == "dotradius" ) {
            // use the dotradius "clustering" method (it's not really clustering..)
            $location_features = get_features_dotradius($Model, $bounds);

        } elseif ( $cluster_type == "dotgrid" ) {
            // use dotgrid clustering
            $location_features = get_features_dotgrid($Model, $bounds);

        } elseif ( $cluster_type == "dotgriddetail" ) {
            // use dotgrid clustering
            $location_features = get_features_dotgrid_detail($Model, $bounds);

        } elseif ( $cluster_type == "dotgridtrump" ) {
            // use dotgrid clustering
            $location_features = get_features_dotgrid_trump($Model, $bounds);

        } elseif ( $cluster_type == "squaregrid" ) {
            // use dotgrid clustering
            $location_features = get_features_squaregrid($Model, $bounds);

        } else {
            // unrecognised clustering type, or clustering type == none
            foreach($Model->occurrencesInBounds($bounds) as $location) {
                $longitude = $location['longitude'];
                $latitude = $location['latitude'];
                $location_features[] = array(
                    "type" => "Feature",
                    'properties' => array(
                        'title' => "Occurrence",
                        'description' => "<dl><dt>Latitude</dt><dd>$latitude</dd><dt>Longitude</dt><dd>$longitude</dd>",
                        'point_radius' => GeolocationsBehavior::NON_CLUSTERED_FEATURE_RADIUS
                    ),
                    'geometry' => array(
                        'type' => 'Point',
                        'coordinates' => array($longitude, $latitude),
                    ),
                );
            }
        }

        $geoObject = array(
            'type' => 'FeatureCollection',
            'features' => $location_features
        );
        return $geoObject;
    }
}
