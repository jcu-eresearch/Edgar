// Generated by CoffeeScript 1.3.3

/*
# Code to control the classify a habitat interface
*/


(function() {

  Edgar.vetting.classifyHabitat = {
    /*
        # Init the classify Habitat
        #
        # This is run once
    */

    init: function() {
      consolelog("Starting to init the classify habitat interface");
      this.wkt = new OpenLayers.Format.WKT({
        'internalProjection': Edgar.map.baseLayer.projection,
        'externalProjection': Edgar.util.projections.geographic
      });
      this.vectorLayerOptions = {
        /*
                    # NOTE: Due to OpenLayers Bug.. can't do this.
                    #   The modify feature control draws points onto the vector layer
                    #   to show vertice drag points.. these drag points fail the geometryType
                    #   test.
                    # 'geometryType': OpenLayers.Geometry.Polygon
        */

      };
      this._addButtonHandlers();
      consolelog("Finished init-ing the classify habitat interface");
      return null;
    },
    _confirmModeChangeOkayViaDialog: function(newMode) {
      var myDialog;
      myDialog = $("#discard-area-classifcation-confirm").dialog({
        resizable: false,
        width: 400,
        modal: true,
        buttons: {
          "Discard area classification": function() {
            $(this).dialog("close");
            Edgar.vetting.classifyHabitat._removeAllFeatures();
            return $(Edgar.map).trigger('changemode', $(this).data('newMode'));
          },
          Cancel: function() {
            return $(this).dialog("close");
          }
        }
      });
      return myDialog.data('newMode', newMode);
    },
    isChangeModeOkay: function(newMode) {
      if (('vectorLayer' in this) && (this.vectorLayer.features.length > 0)) {
        this._confirmModeChangeOkayViaDialog(newMode);
        return false;
      } else {
        return true;
      }
    },
    /*
        # Code to add button click even handlers to DOM
    */

    _addButtonHandlers: function() {
      /*
              handle draw polygon press
      */

      var vetform, vetpanel;
      $('#newvet_draw_polygon_button').click(function(e) {
        Edgar.vetting.classifyHabitat._handleDrawPolygonClick(e);
        return null;
      });
      /*
              handle add polygon press
      */

      $('#newvet_add_polygon_button').click(function(e) {
        Edgar.vetting.classifyHabitat._handleAddPolygonClick(e);
        return null;
      });
      /*
              handle modify polygon press
      */

      $('#newvet_modify_polygon_button').click(function(e) {
        Edgar.vetting.classifyHabitat._handleModifyPolygonClick(e);
        return null;
      });
      /*
              handle delete selected polygon press
      */

      $('#newvet_delete_selected_polygon_button').click(function(e) {
        Edgar.vetting.classifyHabitat._handleDeleteSelectedPolygonClick(e);
        return null;
      });
      /*
              handle delete all polygon press
      */

      $('#newvet_delete_all_polygons_button').click(function(e) {
        Edgar.vetting.classifyHabitat._handleDeleteAllPolygonClick(e);
        return null;
      });
      /*
              toggle the ui-state-hover class on hover events
      */

      $('#newvet :button').hover(function() {
        $(Edgar.vetting.classifyHabitat).addClass("ui-state-hover");
        return null;
      }, function() {
        $(Edgar.vetting.classifyHabitat).removeClass("ui-state-hover");
        return null;
      });
      /*
              listen for newvet form submission
      */

      vetpanel = $('#newvet');
      vetform = $('#vetform');
      return $('#vet_submit').click(function(e) {
        var classifyHabitat;
        e.preventDefault();
        classifyHabitat = Edgar.vetting.classifyHabitat;
        /*
                    # validate the form
                    # and, if valid, submit its contents
        */

        if (classifyHabitat._validateNewVetForm()) {
          return classifyHabitat._createNewVetting();
        } else {
          return false;
        }
      });
    },
    engage: function() {
      consolelog("Starting engageClassifyHabitatInterface");
      this._addVectorLayer();
      this._addDrawControl();
      this._addModifyControl();
      consolelog("Finished engageClassifyHabitatInterface");
      return null;
    },
    disengage: function() {
      consolelog("Starting disengageClassifyHabitatInterface");
      this._clearNewVettingMode();
      this._removeDrawControl();
      this._removeModifyControl();
      this._removeVectorLayer();
      return consolelog("Finished disengageClassifyHabitatInterface");
    },
    _addVectorLayer: function() {
      /*
              # Define a vector layer to hold a user's area classification
      */
      this.vectorLayer = new OpenLayers.Layer.Vector("New Area Classification", this.vectorLayerOptions);
      return Edgar.map.addLayers([this.vectorLayer]);
    },
    _removeVectorLayer: function() {
      Edgar.map.removeLayer(this.vectorLayer);
      delete this.vectorLayer;
      return null;
    },
    _addDrawControl: function() {
      this.drawControl = new OpenLayers.Control.DrawFeature(this.vectorLayer, OpenLayers.Handler.Polygon);
      Edgar.map.addControl(this.drawControl);
      return null;
    },
    /*
        # Removes the draw control
        # Note: Assumes _clearNewVettingMode was already run
    */

    _removeDrawControl: function() {
      this.drawControl.map.removeControl(this.modifyControl);
      delete this.drawControl;
      return null;
    },
    _addModifyControl: function() {
      /*
              # Create a Modify Feature control
              # Allow users to:
              #    - Reshape
              #    - Drag
      */
      this.modifyControl = new OpenLayers.Control.ModifyFeature(this.vectorLayer, {
        mode: OpenLayers.Control.ModifyFeature.RESHAPE | OpenLayers.Control.ModifyFeature.DRAG,
        beforeSelectFeature: function(feature) {
          $('#newvet_delete_selected_polygon_button').attr("disabled", false).removeClass("ui-state-disabled");
          return null;
        },
        unselectFeature: function(feature) {
          $('#newvet_delete_selected_polygon_button').attr("disabled", true).addClass("ui-state-disabled");
          return null;
        }
      });
      Edgar.map.addControl(this.modifyControl);
      return null;
    },
    /*
        # Removes the modify control
        # Note: Assumes _clearNewVettingMode was already run
    */

    _removeModifyControl: function() {
      this.modifyControl.map.removeControl(this.modifyControl);
      delete this.modifyControl;
      return null;
    },
    _clearNewVettingMode: function(e) {
      consolelog("Clearing classify habitat mode of operation");
      this._removeModifyFeatureHandlesAndVertices();
      this.drawControl.deactivate();
      $('#newvet_draw_polygon_button').removeClass('ui-state-active');
      this.modifyControl.deactivate();
      $('#newvet_modify_polygon_button').removeClass('ui-state-active');
      this._updateNewVetHint();
      return null;
    },
    _activateDrawPolygonMode: function() {
      this._clearNewVettingMode();
      $('#newvet_draw_polygon_button').addClass('ui-state-active');
      this.drawControl.activate();
      this._updateNewVetHint();
      return null;
    },
    _activateModifyPolygonMode: function() {
      this._clearNewVettingMode();
      $('#newvet_modify_polygon_button').addClass('ui-state-active');
      this.modifyControl.mode = OpenLayers.Control.ModifyFeature.RESHAPE | OpenLayers.Control.ModifyFeature.DRAG;
      this.modifyControl.activate();
      return this._updateNewVetHint();
    },
    _handleToggleButtonClick: function(e, onActivatingButton, onDeactivatingButton) {
      e.preventDefault();
      if ($(e.srcElement).hasClass('ui-state-active')) {
        onDeactivatingButton.apply(Edgar.vetting.classifyHabitat, []);
      } else {
        onActivatingButton.apply(Edgar.vetting.classifyHabitat, []);
      }
      return null;
    },
    _handleDrawPolygonClick: function(e) {
      this._handleToggleButtonClick(e, this._activateDrawPolygonMode, this._clearNewVettingMode);
      return null;
    },
    _handleModifyPolygonClick: function(e) {
      this._handleToggleButtonClick(e, this._activateModifyPolygonMode, this._clearNewVettingMode);
      return null;
    },
    _handleAddPolygonClick: function(e) {
      var attributes, calcDimension, centerOfMap, centerPoint, feature, mapBounds, mapHeight, mapWidth, minorFraction, polygon, radius, rotation, sides;
      e.preventDefault();
      this._clearNewVettingMode();
      centerOfMap = Edgar.map.getCenter();
      mapBounds = Edgar.map.getExtent();
      mapHeight = mapBounds.top - mapBounds.bottom;
      mapWidth = mapBounds.right - mapBounds.left;
      calcDimension = null;
      if (mapHeight > mapWidth) {
        calcDimension = mapHeight;
      } else {
        calcDimension = mapWidth;
      }
      minorFraction = calcDimension / 14;
      radius = minorFraction;
      sides = 6;
      rotation = Math.random() * 90;
      centerPoint = new OpenLayers.Geometry.Point(centerOfMap.lon, centerOfMap.lat);
      polygon = OpenLayers.Geometry.Polygon.createRegularPolygon(centerPoint, radius, sides, rotation);
      attributes = {};
      feature = new OpenLayers.Feature.Vector(polygon, attributes);
      this.vectorLayer.addFeatures([feature]);
      consolelog(this.vectorLayer.features);
      this._activateModifyPolygonMode();
      return null;
    },
    _removeAllFeatures: function() {
      return this.vectorLayer.removeFeatures(this.vectorLayer.features);
    },
    _removeModifyFeatureHandlesAndVertices: function() {
      this.vectorLayer.removeFeatures(this.modifyControl.virtualVertices, {
        silent: true
      });
      this.vectorLayer.removeFeatures(this.modifyControl.vertices, {
        silent: true
      });
      this.vectorLayer.removeFeatures(this.modifyControl.radiusHandle, {
        silent: true
      });
      this.vectorLayer.removeFeatures(this.modifyControl.dragHandle, {
        silent: true
      });
      return null;
    },
    _handleDeleteSelectedPolygonClick: function(e) {
      var currentFeature;
      e.preventDefault();
      currentFeature = this.modifyControl.feature;
      if (currentFeature) {
        this.modifyControl.unselectFeature(currentFeature);
        this._removeModifyFeatureHandlesAndVertices();
        this.vectorLayer.removeFeatures(currentFeature);
        if (this.vectorLayer.features.length === 0) {
          this._clearNewVettingMode();
        }
      }
      return null;
    },
    _handleDeleteAllPolygonClick: function(e) {
      e.preventDefault();
      this._clearNewVettingMode();
      this.vectorLayer.removeAllFeatures();
      this._updateNewVetHint();
      return null;
    },
    _updateNewVetHint: function() {
      var drawPolygonHints, hint, modifyPolygonHints, movePolygonHints;
      drawPolygonHints = [''];
      modifyPolygonHints = ['<p>Press the <strong>Delete</strong> key while hovering your mouse cursor over a corner to delete it</p>'];
      movePolygonHints = [''];
      if (this.modifyControl.active) {
        hint = modifyPolygonHints[Math.floor(Math.random() * modifyPolygonHints.length)];
        $('#vethint').html(hint);
      } else if (this.drawControl.active) {
        hint = drawPolygonHints[Math.floor(Math.random() * drawPolygonHints.length)];
        $('#vethint').html(hint);
      } else {
        $('#vethint').html('');
      }
      return null;
    },
    _createNewVetting: function() {
      var feature, layerWKTString, newVetData, newVetPolygon, newVetPolygonFeatures, newVetPolygonGeoms, speciesId, url, vetDataAsJSONString, _i, _len;
      consolelog("Processing create new vetting");
      newVetPolygonFeatures = this.vectorLayer.features;
      newVetPolygonGeoms = [];
      for (_i = 0, _len = newVetPolygonFeatures.length; _i < _len; _i++) {
        feature = newVetPolygonFeatures[_i];
        newVetPolygonGeoms.push(feature.geometry);
      }
      newVetPolygon = new OpenLayers.Geometry.MultiPolygon(newVetPolygonGeoms);
      consolelog("WKT logs:");
      consolelog("polygon", newVetPolygon);
      layerWKTString = this.wkt.extractGeometry(newVetPolygon);
      consolelog("layer string", layerWKTString);
      speciesId = Edgar.mapdata.species.id;
      newVetData = {
        area: layerWKTString,
        species_id: speciesId,
        comment: $("#vetcomment").val(),
        classification: $("#vetclassification").val()
      };
      consolelog("Post Data", newVetData);
      vetDataAsJSONString = JSON.stringify(newVetData);
      consolelog("Post Data as JSON", vetDataAsJSONString);
      url = Edgar.baseUrl + "species/insert_vetting/" + speciesId + ".json";
      $.ajax(url, {
        type: "POST",
        data: vetDataAsJSONString,
        success: function(data, textStatus, jqXHR) {
          return alert("Successfully created your vetting. Please reload this page in your browser...(Note.. this is a temporary work-around)");
        },
        error: function(jqXHR, textStatus, errorThrown) {
          return alert("Failed to create vetting: " + errorThrown + ". Please ensure your classified area is a simple polygon (i.e. its boundaries don't cross each other)");
        },
        complete: function(jqXHR, textStatus) {},
        dataType: 'json'
      });
      return true;
    },
    _validateNewVetForm: function() {
      var newVetPolygonFeatures;
      newVetPolygonFeatures = this.vectorLayer.features;
      if (Edgar.mapdata.species === null) {
        alert("No species selected");
        return false;
      } else if (newVetPolygonFeatures.length === 0) {
        alert("No polygons provided");
        $('#newvet_add_polygon_button').effect("highlight", {}, 5000);
        return false;
      } else if ($('#vetclassification').val() === '') {
        alert("No classification provided");
        $('#vetclassification').effect("highlight", {}, 5000);
        return false;
      } else {
        return true;
      }
    }
  };

}).call(this);
