// Generated by CoffeeScript 1.3.3
(function() {
  var DETAIL_PAGE_SIZE, DetailPopup, tabIdCounter;

  tabIdCounter = 1;

  DETAIL_PAGE_SIZE = 5;

  DetailPopup = (function() {

    function DetailPopup(feature, onClose) {
      var relPosition, self;
      this.feature = feature;
      this.onClose = onClose;
      this.detailsPageIdx = null;
      this.hasClosed = false;
      self = this;
      this.popup = new OpenLayers.Popup.Anchored('featurePopup', this.feature.geometry.getBounds().getCenterLonLat(), new OpenLayers.Size(400, 247), Edgar.templates.mapPopup(this.feature.attributes), null, false, function() {
        return self.endPopup();
      });
      this.feature.layer.map.addPopup(this.popup);
      relPosition = this.popup.relativePosition;
      $(this.popup.div).addClass(relPosition);
      this.initPopupContent();
      this.feature.layer.events.register('featureunselected', this, this.endPopup);
      this.feature.layer.map.events.register('zoomend', this, this.endPopup);
    }

    DetailPopup.prototype.endPopup = function() {
      if (this.hasClosed) {
        return;
      }
      this.hasClosed = true;
      this.feature.layer.map.events.unregister('zoomend', this, this.endPopup);
      this.feature.layer.events.unregister('featureunselected', this, this.endPopup);
      this.feature.layer.map.removePopup(this.popup);
      this.popup.destroy();
      return this.onClose();
    };

    DetailPopup.prototype.initPopupContent = function() {
      var $tabsElem, self, tabPrefix;
      $tabsElem = $(this.popup.contentDiv).find('.map-popup-tabs');
      self = this;
      $tabsElem.find('.close-button').click(function() {
        return self.endPopup();
      });
      tabPrefix = "popup" + (tabIdCounter++);
      $tabsElem.find('ul.tab-strip > li > a').each(function(idx, elem) {
        return $(elem).attr('href', "\#" + tabPrefix + "-tab" + (idx + 1));
      });
      $tabsElem.children('.tab-panel').each(function(idx, elem) {
        return $(elem).attr('id', "" + tabPrefix + "-tab" + (idx + 1));
      });
      return $tabsElem.tabs({
        select: function(event, ui) {
          return self.onTabSelected(ui);
        }
      });
    };

    DetailPopup.prototype.onTabSelected = function(ui) {
      if ($(ui.panel).hasClass('details-panel') && !(this.detailsPageIdx != null)) {
        return this.loadDetails(0);
      }
    };

    DetailPopup.prototype.loadDetails = function(pageIdx) {
      var $detailsPanel, bbox, self;
      if (this.hasClosed) {
        return;
      }
      if (pageIdx < 0) {
        return;
      }
      this.detailsPageIdx = pageIdx;
      $detailsPanel = $(this.popup.contentDiv).find('.details-panel');
      $detailsPanel.html(Edgar.templates.mapPopupLoading({
        baseUrl: Edgar.baseUrl
      }));
      bbox = this.feature.data.gridBounds;
      self = this;
      return $.ajax({
        url: "" + Edgar.baseUrl + "species/geo_json_occurrences/" + Edgar.mapdata.species.id + ".json",
        dataType: 'json',
        data: {
          bound: true,
          clustered: 'none',
          limit: DETAIL_PAGE_SIZE,
          offset: DETAIL_PAGE_SIZE * self.detailsPageIdx,
          bbox: "" + bbox.minlon + "," + bbox.minlat + "," + bbox.maxlon + "," + bbox.maxlat
        },
        success: (function(data, status, xhr) {
          return self.showDetails(data);
        }),
        error: function(data, status, xhr) {
          console.log('Failed to fetch occurrence details (data/status/xhr):');
          console.log(data);
          console.log(status);
          console.log(xhr);
          return setTimeout((function() {
            return self.loadDetails(self.detailsPageIdx);
          }), 2000);
        }
      });
    };

    DetailPopup.prototype.showDetails = function(details) {
      var $detailsPanel, html;
      if (this.hasClosed) {
        return;
      }
      details.pageIdx = this.detailsPageIdx;
      details.pageSize = DETAIL_PAGE_SIZE;
      details.totalOccurrences = this.totalOccurrencesInFeature();
      console.log(details);
      html = Edgar.templates.mapPopupDetailsPanel(details);
      $detailsPanel = $(this.popup.contentDiv).find('.details-panel');
      $detailsPanel.html(html);
      return this.initDetailPanel($detailsPanel);
    };

    DetailPopup.prototype.initDetailPanel = function($detailsPanel) {
      var self;
      self = this;
      $detailsPanel.find('.next-page').click(function() {
        return self.loadDetails(self.detailsPageIdx + 1);
      });
      return $detailsPanel.find('.prev-page').click(function() {
        return self.loadDetails(self.detailsPageIdx - 1);
      });
    };

    DetailPopup.prototype.totalOccurrencesInFeature = function() {
      var row, total, _i, _len, _ref;
      total = 0;
      _ref = this.feature.data.classificationTotals;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        row = _ref[_i];
        if (!row.isGrandTotal) {
          total += row.total;
        }
      }
      return total;
    };

    return DetailPopup;

  })();

  window.Edgar = window.Edgar || {};

  window.Edgar.DetailPopup = DetailPopup;

}).call(this);
