// Generated by CoffeeScript 1.3.3
(function() {
  var DetailPopup;

  DetailPopup = (function() {

    function DetailPopup(feature, onClose) {
      var self;
      this.feature = feature;
      this.onClose = onClose;
      self = this;
      console.log(this.feature.attributes);
      this.popup = new OpenLayers.Popup.FramedCloud("featurePopup", this.feature.geometry.getBounds().getCenterLonLat(), new OpenLayers.Size(100, 100), Edgar.templates.detailPopupContent(this.feature.attributes), null, true, function() {
        return self.endPopup();
      });
      this.feature.layer.map.addPopup(this.popup);
      this.feature.layer.events.register('featureunselected', this, this.endPopup);
      this.feature.layer.map.events.register('zoomend', this, this.endPopup);
    }

    DetailPopup.prototype.endPopup = function() {
      this.feature.layer.map.events.unregister('zoomend', this, this.endPopup);
      this.feature.layer.events.unregister('featureunselected', this, this.endPopup);
      this.feature.layer.map.removePopup(this.popup);
      this.popup.destroy();
      return this.onClose();
    };

    return DetailPopup;

  })();

  window.Edgar = window.Edgar || {};

  window.Edgar.DetailPopup = DetailPopup;

}).call(this);
