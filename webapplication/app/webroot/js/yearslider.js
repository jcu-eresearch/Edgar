(function($){

    window.Edgar = window.Edgar || {};
    Edgar.YearSlider = function(options) {
        //options
        options = $.extend({
            sliderElem: null,   // REQUIRED: empty div that will be converted into a slider
            scenarioElem: null, // REQUIRED: <select> element containing emission scenario names
            map: null,          // REQUIRED: the open layers map object
            yearLabelElem: null,     // Will change the inner text of this elem when the year changes
            defaultYear: 2010,
            minYear: 1990,
            maxYear: 2080,
            defaultScenario: 'sresa1b'
        }, options);

        this.MIN_YEAR = parseInt(options.minYear);
        this.MAX_YEAR = parseInt(options.maxYear);

        //member vars (private)
        this._year = parseInt(options.defaultYear);
        this._layersByYear = {};
        this._map = options.map;
        this._speciesId = null;
        this._scenario = options.defaultScenario
        this._$slider = $(options.sliderElem);
        this._$scenarios = $(options.scenarioElem);
        this._$yearLabel = (options.yearLabelElem === null ? null : $(options.yearLabelElem));
        var self = this;

        //initial setup
        $(document).ready(function(){
            //init slider
            self._$slider.slider({
                min: self.MIN_YEAR,
                max: self.MAX_YEAR,
                value: self._year,
                change: function(event, ui){
                    self.setYear(ui.value);
                }
            });

            //init year label
            if(self._$yearLabel) self._$yearLabel.text(''+self._year);

            //init scenarios
            self._$scenarios.val(self._scenario);
            self._$scenarios.change(function(){
                self.setScenario($(this).val());
            });
        });

        this.setYear = function(year){
            year = parseInt(year);
            if(this._year == year) return;

            this._year = year;

            if(this._year > 2050){
                //TODO: change site logo to cyborg raven
            }

            if(this._$yearLabel) this._$yearLabel.text(''+this._year);
            this._setLayerOpacities();
        }

        /*!
        *  Disable by setting species id to null
        */
        this.setSpeciesId = function(speciesId){
            if(speciesId !== null)
                speciesId = parseInt(speciesId);

            if(this._speciesId === speciesId) return;

            this._speciesId = speciesId;
            this._reloadLayers();
        }

        this.setScenario = function(scenario){
            scenario = ''+scenario;
            if(this._scenario == scenario) return;

            this._scenario = scenario;
            this._reloadLayers();
        }

        this._reloadLayers = function(){
            //remove all layers
            var self = this;
            $.each(this._layersByYear, function(year, layer){
                self._map.removeLayer(layer);
            });
            this._layersByYear = {};

            //readd layers if enabled
            if(this._speciesId){
                this._addLayerForYear(1990);
                this._addLayerForYear(2000);
                this._addLayerForYear(2010);
                this._addLayerForYear(2020);
                this._addLayerForYear(2030);
                this._addLayerForYear(2040);
                this._addLayerForYear(2050);
                this._addLayerForYear(2060);
                this._addLayerForYear(2070);
                this._addLayerForYear(2080);
                this._setLayerOpacities();
            }
        }

        this._addLayerForYear = function(year){
            var mapPath = '' + this._speciesId + '/' + this._scenario + '.csiro_mk3_5.run1.run1.' + year + '.asc';

            var layer = new OpenLayers.Layer.WMS(
                "Climate Suitability in " + year,
                mapToolBaseUrl + 'wms_with_auto_determined_threshold.php',
                {
                    MODE: 'map',
                    MAP: 'edgar_master.map',
                    DATA: mapPath,
                    SPECIESID: this._speciesId,
                    REASPECT: 'true',
                    TRANSPARENT: 'true'
                },
                {
                    isBaseLayer: false,
                    transitionEffect: 'resize',
                    displayInLayerSwitcher: false,
                    singleTile: true,
                    ratio: 1.5
                }
            );
            this._layersByYear[year] = layer;
            this._map.addLayer(layer);
        }

        this._setLayerOpacities = function(){
            if(!this._speciesId) return;

            var currentYear = this._year;
            var sortedYears = $.map(this._layersByYear, function(layer, year){ return parseInt(year); });
            sortedYears.sort();

            //find two closest years to interpolate between
            var lowerYear = sortedYears[0];
            var upperYear = null;
            $.each(sortedYears, function(idx, year){
                if(year >= currentYear){
                    upperYear = year;
                    return false; //stops iteration
                } else {
                    lowerYear = year;
                }
            });

            //if exactly on a year, no interpolation necessary
            if(upperYear == currentYear){
                $.each(this._layersByYear, function(year, layer){
                    layer.setOpacity((year == currentYear ? 1 : 0));
                });
            } else {
                //else, interpolate
                $.each(this._layersByYear, function(year, layer){
                    var interp = (currentYear - lowerYear) / (upperYear - lowerYear);
                    var opacity = 0;
                    if(year == upperYear){
                        opacity = interp;
                    } else if(year == lowerYear){
                        opacity = 1 - interp;
                    }
                    layer.setOpacity(opacity);
                });
            }
        }
    };

})(jQuery);
