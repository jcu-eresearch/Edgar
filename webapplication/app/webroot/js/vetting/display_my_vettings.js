// Generated by CoffeeScript 1.3.3

/*
# Code to control the classify a habitat interface
*/


(function() {

  Edgar.vetting.myHabitatClassifications = {
    /*
        # Init the my habitat classifications
        #
        # This is run once
    */

    init: function() {
      consolelog("Starting to init the my habitat classifications interface");
      consolelog("Finished init-ing the classify habitat interface");
      return null;
    },
    _addVectorLayer: function() {
      this.vectorLayer = new OpenLayers.Layer.Vector('My Habitat Classifications', {
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
            by_user_id: Edgar.user.id
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
      $myVettingsList = $('#my_vettings_list');
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
          Edgar.vetting.myHabitatClassifications.selectControl.select(thisFeature);
          return $(this).addClass("ui-state-hover");
        }, function() {
          Edgar.vetting.myHabitatClassifications.selectControl.unselectAll();
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
      consolelog("Starting engageMyHabitatClassifications");
      this._addVectorLayer();
      this._addSelectControl();
      this._addLoadEndListener();
      this._vectorLayerUpdated();
      consolelog("Finished engageMyHabitatClassifications");
      return null;
    },
    disengage: function() {
      consolelog("Starting disengageMyHabitatClassifications");
      this._removeLoadEndListener();
      this._removeSelectControl();
      this._removeVectorLayer();
      return consolelog("Finished disengageMyHabitatClassifications");
    },
    isChangeModeOkay: function(newMode) {
      return true;
    }
  };

}).call(this);
