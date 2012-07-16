// Generated by CoffeeScript 1.3.3

/*
# Code to control the classify a habitat interface
*/


(function() {

  Edgar.vetting.theirHabitatClassifications = {
    /*
        # Init the their habitat classifications
        #
        # This is run once
    */

    init: function() {
      consolelog("Starting to init the their habitat classifications interface");
      consolelog("Finished init-ing the classify their habitat interface");
      return null;
    },
    _addVectorLayer: function() {
      this.vectorLayer = new OpenLayers.Layer.Vector('Their Habitat Classifications', {
        isBaseLayer: false,
        projection: Edgar.util.projections.geographic,
        strategies: [
          new OpenLayers.Strategy.BBOX({
            resFactor: 1.1
          })
        ],
        protocol: new OpenLayers.Protocol.HTTP({
          url: Edgar.baseUrl + "species/vetting_geo_json/" + Edgar.mapdata.species.id + ".json",
          format: new OpenLayers.Format.GeoJSON({}),
          params: {
            by_user_id: Edgar.user.id,
            inverse_user_id_filter: true
          }
        }),
        styleMap: Edgar.vetting.areaStyleMap
      });
      return Edgar.map.addLayer(this.vectorLayer);
    },
    _removeVectorLayer: function() {
      Edgar.map.removeLayer(this.vectorLayer);
      delete this.vectorLayer;
      return null;
    },
    _addSelectControl: function() {
      this.selectControl = new OpenLayers.Control.SelectFeature(this.vectorLayer);
      return Edgar.map.addControl(this.selectControl);
    },
    _removeSelectControl: function() {
      return Edgar.map.removeControl(this.selectControl);
    },
    _addLoadEndListener: function() {
      return this.vectorLayer.events.register('loadend', this, this._vectorLayerUpdated);
    },
    _removeLoadEndListener: function() {
      return this.vectorLayer.events.unregister('loadend', this, this._vectorLayerUpdated);
    },
    _vectorLayerUpdated: function() {
      var $myVettingsList, addVettingToVettingsList, feature, features, _i, _len;
      $myVettingsList = $('#their_vettings_list');
      $myVettingsList.empty();
      features = this.vectorLayer.features;
      addVettingToVettingsList = function(feature, $ul) {
        var $liVetting, classification, comment, featureData;
        featureData = feature.data;
        classification = featureData['classification'];
        comment = featureData['comment'];
        $liVetting = $('<li class="ui-state-default"><span class="classification">' + classification + '</span><span class="comment">' + comment + '</span></li>');
        $liVetting.data('feature', feature);
        $liVetting.hover(function() {
          var thisFeature;
          thisFeature = $(this).data('feature');
          Edgar.vetting.theirHabitatClassifications.selectControl.select(thisFeature);
          return $(this).addClass("ui-state-hover");
        }, function() {
          Edgar.vetting.theirHabitatClassifications.selectControl.unselectAll();
          return $(this).removeClass("ui-state-hover");
        });
        return $ul.append($liVetting);
      };
      for (_i = 0, _len = features.length; _i < _len; _i++) {
        feature = features[_i];
        addVettingToVettingsList(feature, $myVettingsList);
      }
      return null;
    },
    engage: function() {
      consolelog("Starting engageTheirHabitatClassifications");
      this._addVectorLayer();
      this._addSelectControl();
      this._addLoadEndListener();
      this._vectorLayerUpdated();
      consolelog("Finished engageTheirHabitatClassifications");
      return null;
    },
    disengage: function() {
      consolelog("Starting disengageTheirHabitatClassifications");
      this._removeLoadEndListener();
      this._removeSelectControl();
      this._removeVectorLayer();
      return consolelog("Finished disengageTheirHabitatClassifications");
    },
    isChangeModeOkay: function(newMode) {
      return true;
    }
  };

}).call(this);
