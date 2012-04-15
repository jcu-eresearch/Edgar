// Author: Robert Pyke
//
// Assumes that the var species_id has already been set.
// Assumes that open layers, jQuery and jQueryUI are all available.

var map, select_control;
$(document).ready(function() {
		geographic = new OpenLayers.Projection("EPSG:4326");
		mercator = new OpenLayers.Projection("EPSG:900913");

		map = new OpenLayers.Map('map', {
			// Don't let the user move the map outside of the bounds of the earth
			// Some maps support wrap-around, others don't.
			// To make everything simpler (incl. our BBox strategy), just prevent it from happening.
			restrictedExtent: new OpenLayers.Bounds(-180, -90, 180, 90),
			displayProjection: geographic,
			projection: geographic,
		});

		// The standard open layers layer.
		var wms = new OpenLayers.Layer.WMS(
			"OpenLayers WMS",
			"http://vmap0.tiles.osgeo.org/wms/vmap0",
			{'layers':'basic', projection: geographic} 
		);

		var dist = new OpenLayers.Layer.WMS(
			"Distribution",
			map_tool_url,
			// Params to send as part of request (note: keys will be auto-upcased)
			{MODE: 'map', MAP: 'raster.map', DATA: (species_id + '_1975.asc'), SPECIESID: species_id, REASPECT: "false", TRANSPARENT: 'true'},
			{isBaseLayer: false, opacity: 1, projection: geographic}
		);

		// Google Maps Layers
		// These require a google maps API key
		var gphy = new OpenLayers.Layer.Google(
				"Google Physical",
				{
					type: G_PHYSICAL_MAP,
//					'sphericalMercator': true,
//					'maxExtent': new OpenLayers.Bounds(-20037508.34,-20037508.34,20037508.34,20037508.34)
				}
		);
		var gmap = new OpenLayers.Layer.Google(
				"Google Streets", // the default
				{
					numZoomLevels:20,
//					'sphericalMercator': true,
//					'maxExtent': new OpenLayers.Bounds(-20037508.34,-20037508.34,20037508.34,20037508.34)
				}
		);
		var ghyb = new OpenLayers.Layer.Google(
				"Google Hybrid",
				{
					type: G_HYBRID_MAP,
//					'sphericalMercator': true,
//					'maxExtent': new OpenLayers.Bounds(-20037508.34,-20037508.34,20037508.34,20037508.34)
				}
		);
		var gsat = new OpenLayers.Layer.Google(
				"Google Satellite",
				{
					type: G_SATELLITE_MAP,
					numZoomLevels: 22,
//					'sphericalMercator': true,
//					'maxExtent': new OpenLayers.Bounds(-20037508.34,-20037508.34,20037508.34,20037508.34)
				}
		);

		var style = new OpenLayers.Style({
				// externalGraphic: "${img_url}",
				pointRadius: "${point_radius}",
				fillColor: "#ee9900",
				fillOpacity: 0.4,
				strokeOpacity: 0.4
		});

		var mformat = new OpenLayers.Format.GeoJSON({
//			'internalProjection': geographic,
//			'externalProjection': geographic 
		});
		var occurrences = new OpenLayers.Layer.Vector("Occurrences", {
			// resFactor determines how often to update the map.
			// See: http://dev.openlayers.org/docs/files/OpenLayers/Strategy/BBOX-js.html#OpenLayers.Strategy.BBOX.resFactor
			// A setting of 1 will mean the map is updated every time its zoom/bounds change.
			strategies: [new OpenLayers.Strategy.BBOX({resFactor: 1.1})],
			protocol: new OpenLayers.Protocol.HTTP({
					url: "../geo_json_occurrences/" + species_id + ".json",
					params: {
						// Place addition request params here..
						bound: true,
						clustered: true
					},

					// See: http://geojson.org/geojson-spec.html For the GeoJSON spec.
//					format: new OpenLayers.Format.GeoJSON(),
					format: mformat,
			}),
			styleMap: new OpenLayers.StyleMap({
				"default": style,
				"select": {
					"fillColor": "#83aeef",
					"fillOpacity": 0.7,
					"strokeOpacity": 0.7
				},
			})
		});

		function onPopupClose(evt) {
			// 'this' is the popup.
			select_control.unselect(this.feature);
		}

		function onFeatureSelect(evt) {
			feature = evt.feature;
			popup = new OpenLayers.Popup.FramedCloud("featurePopup",
				feature.geometry.getBounds().getCenterLonLat(),
				new OpenLayers.Size(100,100),
				"<h2>" + feature.attributes.title + "</h2>" +
				feature.attributes.description,
				null, true, onPopupClose);
				feature.popup = popup;
				popup.feature = feature;
				map.addPopup(popup);
		}

		function onFeatureUnselect(evt) {
			feature = evt.feature;
			if (feature.popup) {
				popup.feature = null;
				map.removePopup(feature.popup);
				feature.popup.destroy();
				feature.popup = null;
			}
		}

		occurrences.events.on({
			'featureselected': onFeatureSelect,
			'featureunselected': onFeatureUnselect
		});
		
		var select_control = new OpenLayers.Control.SelectFeature(
			occurrences, {hover: false}
		);

		map.addControl(new OpenLayers.Control.Permalink());
		map.addControl(new OpenLayers.Control.MousePosition());
		map.addControl(select_control);
		select_control.activate();
		
		// Let the user change between layers
		map.addControl(new OpenLayers.Control.LayerSwitcher());

//		map.addLayers([wms, gphy, gmap, ghyb, gsat, dist, occurrences]);
		map.addLayers([wms, dist, occurrences]);
		
		// Zoom the map to cover the world.
		//map.zoomToMaxExtent();

		// Zoom the map to cover Australia
		zoomBounds = new OpenLayers.Bounds();
		zoomBounds.extend(new OpenLayers.LonLat(140,-40));
		zoomBounds.extend(new OpenLayers.LonLat(160,-10));

		map.zoomToExtent(zoomBounds);
});
