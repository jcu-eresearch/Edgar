(function($){

    window.Edgar = window.Edgar || {};
    Edgar.YearSlider = function(options) {
        //options
        options = $.extend({
            sliderElem: null,       // REQUIRED: empty div that will be converted into a slider
            scenarioElemName: null, // REQUIRED: name of <radio> elements for selecting an emission scenario
            map: null,              // REQUIRED: the open layers map object
            yearLabelElem: null,    // Will change the inner text of this elem when the year changes
            defaultYear: 2015,
        }, options);

        this.MIN_YEAR = 2015;
        this.MAX_YEAR = 2085;

        //member vars (private)
        this._year = parseInt(options.defaultYear);
        this._layersByYear = {};
        this._map = options.map;
        this._speciesId = null;
        this._$slider = $(options.sliderElem);
        this._$scenarios = $('input[name=' + options.scenarioElemName + ']');
        this._$yearLabel = (options.yearLabelElem === null ? null : $(options.yearLabelElem));
        var self = this;

        //initial setup
        $(document).ready(function(){
            //init slider
            self._$slider.slider({
                min: self.MIN_YEAR,
                max: self.MAX_YEAR,
                value: self._year,
                step: 10,
                change: function(event, ui){
                    self.setYear(ui.value);
                },
                slide: function(event, ui){
                    self.setYear(ui.value);
                }
            });

            //init year label
            if(self._$yearLabel) self._$yearLabel.text(''+self._year);

            //init scenarios
            self._$scenarios.change(function(){
                setTimeout(function(){
                    self.setScenario();
                }, 1);
            });
       });

        this.setYear = function(year){
            year = parseInt(year);
            if(this._year == year) return;

            this._year = year;
            this._$slider.slider("value", this._year);

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

        this.setScenario = function(){
            scenario = '' + self._$scenarios.filter(':checked').val();
            if(this._scenario == scenario) return;

            this._scenario = scenario;
            this._reloadLayers();
        }

        this.playAnimation = function(){
            var self = this;

            // switch the step to 1 to get smooth transitions between years
            self._$slider.slider('option', 'step', 1);

            var dummyElem = $('<div></div>').css('height', this.MIN_YEAR);
            dummyElem.animate({height: this.MAX_YEAR}, {
                duration: 5000,
                easing: 'linear',
                step: function(year){
                    self.setYear(year);
                },
                complete: function() {
                    self._$slider.slider('option', 'step', 10);
                }
            });
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
                this._addLayerForYear(2015);
                this._addLayerForYear(2025);
                this._addLayerForYear(2035);
                this._addLayerForYear(2045);
                this._addLayerForYear(2055);
                this._addLayerForYear(2065);
                this._addLayerForYear(2075);
                this._setLayerOpacities();
            }
        }

        this._addLayerForYear = function(year){
            var mapPath = Edgar.util.mappath(this._speciesId, year, this._scenario);

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
            // finally, update the year indicator
            var $thumb = this._$slider.slider("widget").find('a');
            
            var left = $thumb.position().left + this._$slider.position().left - ($thumb.width() / 2) - this._$yearLabel.width();
            this._$yearLabel.css('left', left + "px");
        }
    };

})(jQuery);
