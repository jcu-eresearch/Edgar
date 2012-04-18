/* Copyright (c) 2006-2008 MetaCarta, Inc., published under the Clear BSD
 * license.  See http://svn.openlayers.org/trunk/openlayers/license.txt for the
 * full text of the license. */

/** 
 * @requires OpenLayers/Control.js
 */

/**
 * Class: OpenLayers.Control.LayerSwitcher
 *
 * Inherits from:
 *  - <OpenLayers.Control>
 */
OpenLayers.Control.ExtendedLayerSwitcher = 
  OpenLayers.Class(OpenLayers.Control, {
    
    /**  
     * Property: activeColor
     * {String}
     */
    activeColor: "white",
    
    /**  
     * Property: layerStates 
     * {Array(Object)} Basically a copy of the "state" of the map's layers 
     *     the last time the control was drawn. We have this in order to avoid
     *     unnecessarily redrawing the control.
     */
    layerStates: null,    
        
    /** 
     * Property: useLegendGraphics
     */
    useLegendGraphics: false,    

  // DOM Elements
  
    /**
     * Property: layersDiv
     * {DOMElement} 
     */
    layersDiv: null,
    
    /** 
     * Property: baseLayersDiv
     * {DOMElement}
     */
    baseLayersDiv: null,

    /** 
     * Property: baseLayersTitleDiv
     * {DOMElement}
     */
    baseLayersTitleDiv: null,

    /** 
     * Property: baseLayers
     * {Array(<OpenLayers.Layer>)}
     */
    baseLayers: null,    
    
    /** 
     * Property: dataLayersDiv
     * {DOMElement} 
     */
    dataLayersDiv: null,

    /** 
     * Property: dataLayersTitleDiv
     * {DOMElement} 
     */
    dataLayersTitleDiv: null,

    /** 
     * Property: dataLayers
     * {Array(<OpenLayers.Layer>)} 
     */
    dataLayers: null,

    /** 
     * Property: activeLayer
     */
    activeLayer: null,
    
    /** 
     * Property: minimizeDiv
     * {DOMElement} 
     */
    minimizeDiv: null,

    /** 
     * Property: maximizeDiv
     * {DOMElement} 
     */
    maximizeDiv: null,
    
    /**
     * APIProperty: ascending
     * {Boolean} 
     */
    ascending: true,
 
    /**
     * Constructor: OpenLayers.Control.LayerSwitcher
     * 
     * Parameters:
     * options - {Object}
     */
    initialize: function(options) {
        OpenLayers.Control.prototype.initialize.apply(this, arguments);
        this.layerStates = [];     
    },

    /**
     * APIMethod: destroy 
     */    
    destroy: function() {
        
        OpenLayers.Event.stopObservingElement(this.div);

        OpenLayers.Event.stopObservingElement(this.minimizeDiv);
        OpenLayers.Event.stopObservingElement(this.maximizeDiv);

        //clear out layers info and unregister their events 
        this.clearLayersArray("base");
        this.clearLayersArray("data");
        
        this.map.events.un({
            "addlayer": this.redraw,
            "changelayer": this.redraw,
            "removelayer": this.redraw,
            "changebaselayer": this.redraw,
            scope: this
        });

        OpenLayers.Control.prototype.destroy.apply(this, arguments);
    },

    /** 
     * Method: setMap
     *
     * Properties:
     * map - {<OpenLayers.Map>} 
     */
    setMap: function(map) {
        OpenLayers.Control.prototype.setMap.apply(this, arguments);
        
        this.map.events.on({
            "addlayer": this.redraw,
            "changelayer": this.redraw,
            "removelayer": this.redraw,
            "changebaselayer": this.redraw,
            scope: this
        });
    },

    /**
     * Method: draw
     *
     * Returns:
     * {DOMElement} A reference to the DIV DOMElement containing the 
     *     switcher tabs.
     */  
    draw: function() {
        OpenLayers.Control.prototype.draw.apply(this);

        // create layout divs
        this.loadContents();

        // set mode to minimize
        if(!this.outsideViewport) {
            this.minimizeControl();
        }

        // populate div with current info
        this.redraw();

        return this.div;       
    },

    /** 
     * Method: clearLayersArray
     * User specifies either "base" or "data". we then clear all the
     *     corresponding listeners, the div, and reinitialize a new array.
     * 
     * Parameters:
     * layersType - {String}  
     */
    clearLayersArray: function(layersType) {
        var layers = this[layersType + "Layers"];
        if (layers) {
            for(var i=0, len=layers.length; i<len ; i++) {
                var layer = layers[i];
                OpenLayers.Event.stopObservingElement(layer.inputElem);
                OpenLayers.Event.stopObservingElement(layer.labelSpan);
            }
        }
        var copy_of_titleDiv;
        if (window.ie) {
            copyTitleDiv = this[layersType + "LayersTitleDiv"].cloneNode(true);
        }
        this[layersType + "LayersDiv"].innerHTML = "";
        if (layers || layersType == "base") {
            if (window.ie) {
                this[layersType + "LayersDiv"].appendChild(copyTitleDiv);
            } else {
                this[layersType + "LayersDiv"].appendChild(this[layersType+"LayersTitleDiv"]);
            }
        }
        this[layersType + "Layers"] = [];
    },


    /**
     * Method: checkRedraw
     * Checks if the layer state has changed since the last redraw() call.
     * 
     * Returns:
     * {Boolean} The layer state changed since the last redraw() call. 
     */
    checkRedraw: function() {
        var redraw = false;
        if ( !this.layerStates.length ||
             (this.map.layers.length != this.layerStates.length) ) {
            redraw = true;
        } else {
            for (var i=0, len=this.layerStates.length; i<len; i++) {
                var layerState = this.layerStates[i];
                var layer = this.map.layers[i];
                if ( (layerState.name != layer.name) || 
                     (layerState.inRange != layer.inRange) || 
                     (layerState.id != layer.id) || 
                     (layerState.visibility != layer.visibility) ) {
                    redraw = true;
                    break;
                }    
            }
        }    
        return redraw;
    },
    
    /** 
     * Method: redraw
     * Goes through and takes the current state of the Map and rebuilds the
     *     control to display that state. Groups base layers into a 
     *     radio-button group and lists each data layer with a checkbox.
     *
     * Returns: 
     * {DOMElement} A reference to the DIV DOMElement containing the control
     */  
    redraw: function() { 
        // if the state hasn't changed since last redraw, no need 
        // to do anything. Just return the existing div.

        if (!this.checkRedraw()) {        
            return this.div;
        } 

        

        //clear out previous layers 
        this.clearLayersArray("base");
        this.clearLayersArray("data");
       
        var containsOverlays = false;
        var containsBaseLayers = false;
        
        
        // Save state -- for checking layer if the map state changed.
        // We save this before redrawing, because in the process of redrawing
        // we will trigger more visibility changes, and we want to not redraw
        // and enter an infinite loop.
        var len = this.map.layers.length;
        this.layerStates = new Array(len);
        for (var i=0; i <len; i++) {
            var layer = this.map.layers[i];            
            this.layerStates[i] = {
                'name': layer.name, 
                'visibility': layer.visibility,
                'inRange': layer.inRange,
                'id': layer.id                
            };
        }    

        var layers = this.map.layers.slice();
        if (!this.ascending) { layers.reverse(); }
        for(var i=0, len=layers.length; i<len; i++) {
            var layer = layers[i];
            var baseLayer = layer.isBaseLayer;
            
            if (layer.displayInLayerSwitcher) {

                if (baseLayer) {
                    containsBaseLayers = true;
                } else {
                    containsOverlays = true;
                }               

                // only check a baselayer if it is *the* baselayer, check data
                // layers if they are visible
                var checked = (baseLayer) ? (layer == this.map.baseLayer)
                                          : layer.getVisibility();               
                
                var layerWrapper = document.createElement("div");
                layerWrapper.style.margin = "4px 0 0 0";
                layerWrapper.id = "layer_" + layer.id;                
               
                // create input element
                var inputElem = null;
                inputElem = document.createElement("input");
                inputElem.id = this.id + "_input_" + layer.name;
                inputElem.name = (baseLayer) ? "baseLayers" : layer.name;
                inputElem.type = (baseLayer) ? "radio" : "checkbox";
                inputElem.value = layer.name;
                inputElem.checked = checked;
                inputElem.defaultChecked = checked; 
                inputElem.style.margin = "2px";
                inputElem.style.background_color = "red";

                if (!baseLayer && !layer.inRange) {
                    inputElem.disabled = true;
                }

                // create the label span
                var labelSpan = document.createElement("span");
                if (!baseLayer && !layer.inRange) {
                    labelSpan.style.color = "gray";
                }
                
                if(layer.queryable) {
                    labelSpan.style.cursor = "pointer";
                }
                labelSpan.innerHTML = layer.name;
                labelSpan.style.display = "block";
                //labelSpan.style.width = "210px";
                labelSpan.style.padding = "0px 6px 2px 4px";
                labelSpan.style.verticalAlign = (baseLayer) ? "bottom" : "baseline";     
                
                var abstractSpan = document.createElement("span");
                abstractSpan.id = "abstract_" + layer.id;
                abstractSpan.innerHTML = layer.description;
                abstractSpan.style.display = "none";
                abstractSpan.style.fontWeight = "normal";
                abstractSpan.style.padding = "0px 6px 2px 5px";
                abstractSpan.style.fontSize = "11px";
                
                var abstractToolbarSpan = document.createElement("span");
                abstractToolbarSpan.style.display = "block";
                    
                abstractSpan.appendChild(abstractToolbarSpan);
                
                if(layer.dataURL) {
                    var dataUrlLink = document.createElement("a");
                    dataUrlLink.style.cursor = "pointer";
                    dataUrlLink.style.display = "inline-block";
                    dataUrlLink.style.margin = "1px";
                    dataUrlLink.alt = "download";
                    dataUrlLink.title = "Download data set"; 
                    dataUrlLink.innerHTML = '<img src="' + OpenLayers.Util.getImagesLocation() + 'download.png" style="border: none;" />';
                    
                    var dataUrlLinkContext = {
                        'url': layer.dataURL
                    };
                    
                    OpenLayers.Event.observe(dataUrlLink, "click", 
                        OpenLayers.Function.bindAsEventListener(this.onDataUrlClick, dataUrlLinkContext)
                    );
                }
                
                if(layer.metadataURL) {
                    var metadataUrlLink = document.createElement("a");
                    metadataUrlLink.style.cursor = "pointer";
                    metadataUrlLink.style.display = "inline-block";
                    metadataUrlLink.style.margin = "0 4px";
                    metadataUrlLink.alt = "metadata";
                    metadataUrlLink.title = "Metadata"; 
                    metadataUrlLink.innerHTML = '<img src="' + OpenLayers.Util.getImagesLocation() + 'metadata.png" style="border: none;" />';
                    
                    var metadataUrlLinkContext = {
                        'url': layer.metadataURL
                    };
                    
                    OpenLayers.Event.observe(metadataUrlLink, "click", 
                        OpenLayers.Function.bindAsEventListener(this.onMetadataUrlClick, metadataUrlLinkContext)
                    );

                    //XXX Dumped this into the normal toolbar
                    //abstractToolbarSpan.appendChild(metadataUrlLink);
                }

                // create the title div
                var titleDiv = document.createElement("div");
                titleDiv.id = "title_" + layer.id;

                if(this.activeLayer == layer.id)
                {
                    titleDiv.style.backgroundColor = "#999";
                }
                else
                {
                    titleDiv.style.backgroundColor = "#e1e1e1";
                }
                
                titleDiv.style.marginLeft = "10px";
                titleDiv.style.width = "90%";
                titleDiv.style.position = "relative";
                titleDiv.style.padding = "4px 2px 2px 2px";
                
                // create the layer operation panel
                var buttonSpan = document.createElement("span");
                buttonSpan.style.padding = "3px 3px 3px 0";
                
                // remove control
//                var removeButton = document.createElement("img");
//               removeButton.src = OpenLayers.Util.getImagesLocation() + "del.png";
//               removeButton.style.cursor = "pointer";
//                removeButton.alt = "Remove layer";
//                removeButton.title = "Remove layer";     
                                
                // layer order controls
                
        //alert("Middle:"+this.dataLayersTitleDiv.innerHTML);

                var abstractButton = document.createElement("img");
                abstractButton.setAttribute("id", "abstractButton_" + layer.id); 
                abstractButton.src = OpenLayers.Util.getImagesLocation() + "expand.png";
                abstractButton.style.cursor = "pointer";
                abstractButton.style.position = "absolute";
                abstractButton.style.top = "0";
                abstractButton.style.right = "0";
                abstractButton.style.padding = "5px";                   

                var context = {
                    'layer': layer,
                    'inputElem': inputElem,
                    'titleDiv': titleDiv,
                    'layerSwitcher': this
                };                   

                OpenLayers.Event.observe(inputElem, "mouseup", 
                    OpenLayers.Function.bindAsEventListener(this.onInputClick, context)
                );

                if(layer.queryable) {
                
                    var queryableButton = document.createElement("img");
                       queryableButton.src = OpenLayers.Util.getImagesLocation() + "queryable.png"; 
                       queryableButton.style.cursor = "pointer";
                       queryableButton.alt = "select for query";
                    queryableButton.title = "select for query";
                    
                    OpenLayers.Event.observe(labelSpan, "click", 
                        OpenLayers.Function.bindAsEventListener(this.onTitleClick, context)
                    );
                    
                    OpenLayers.Event.observe(queryableButton, "click", 
                        OpenLayers.Function.bindAsEventListener(this.onTitleClick, context)
                    );
                }
                
                var abstractContext = {
                    'layer': layer,
                    'button' : abstractButton
                };
                OpenLayers.Event.observe(abstractButton, "mouseup", 
                    OpenLayers.Function.bindAsEventListener(this.toggleAbstract, abstractContext)
                );               
                
                // create line break
                var br = document.createElement("br");
                
                var groupArray = (baseLayer) ? this.baseLayers
                                             : this.dataLayers;
                groupArray.push({
                    'layer': layer,
                    'inputElem': inputElem,
                    'titleDiv': titleDiv,
                    'labelSpan': labelSpan
                });
                                                     
                var groupDiv = (baseLayer) ? this.baseLayersDiv
                                           : this.dataLayersDiv;
                                          
         
                groupDiv.appendChild(layerWrapper);
                layerWrapper.appendChild(titleDiv);  
                titleDiv.appendChild(inputElem);
                titleDiv.appendChild(buttonSpan);                
//                buttonSpan.appendChild(removeButton);
//                buttonSpan.appendChild(opacityMinusButton);
//                opacitySpan.appendChild(opacityImg);
//                buttonSpan.appendChild(opacitySpan);
//                buttonSpan.appendChild(opacityTextInput);
//                buttonSpan.appendChild(opacityPlusButton);
                
                if(layer.description) {
                    titleDiv.appendChild(abstractButton);
                }
                if(layer.queryable) {
                    buttonSpan.appendChild(queryableButton);
                }
                if(layer.dataURL) {
                    buttonSpan.appendChild(dataUrlLink);
                }
                if(layer.metadataURL) {
                    buttonSpan.appendChild(metadataUrlLink);
                }
                
                titleDiv.appendChild(labelSpan); 
                titleDiv.appendChild(abstractSpan);
                
                if(this.useLegendGraphics && layer.params) {
                    var legendGraphicURL = layer.getFullRequestString({
                    REQUEST: "GetLegendGraphic",
                    LAYER: layer.params.LAYERS,
                    FORMAT: "image/png",
                    WIDTH: "150" });

                    //var imgSpan = document.createElement('span');
                    //imgSpan.innerHTML = "<img style=\"display:none\" src=\"" + legendGraphicURL + "\" onload=\"this.style.display = 'inline'\" alt=\"\" onerror=\"this.src='" + OpenLayers.Util.getImagesLocation() + "blank.gif" + "'\" />";
                    //layerWrapper.appendChild(imgSpan);                          
                }                          
            }   
        }
        
        return this.div;        
            
    },   
    
    /** 
     * Method:
     * A label has been clicked, check or uncheck its corresponding input
     * 
     * Parameters:
     * e - {Event} 
     *
     * Context:  
     *  - {DOMElement} inputElem
     *  - {<OpenLayers.Control.LayerSwitcher>} layerSwitcher
     *  - {<OpenLayers.Layer>} layer
     */

    onInputClick: function(e) {
        if (!this.inputElem.disabled) {
            if (this.inputElem.type == "radio") {
                this.inputElem.checked = true;
                this.layer.map.setBaseLayer(this.layer);
            } else {
                this.inputElem.checked = !this.inputElem.checked;
                this.layerSwitcher.updateMap();
            }
        }
        
        if (e != null) {
            OpenLayers.Event.stop(e);                                            
        }
    },    

    /**
     * Method: onRemoveClick
     * Remove the layer from the map
     * 
     * Parameters: 
     * e - {Event} 
     */
    onRemoveClick: function(e)
    {
        map.removeLayer(this.layer);
        
        if (e != null) {
            OpenLayers.Event.stop(e);                                            
        } 
    },
    
    /**
     * Method: onDownClick
     * Set the layer position down one level
     * 
     * Parameters: 
     * e - {Event} 
     */
    onDownClick: function(e)
    {
        map.raiseLayer(this.layer, -1);  
        
        if (e != null) {
            OpenLayers.Event.stop(e);                                            
        }
    },
    
    /**
     * Method: onUpClick
     * Set the layer position up one level
     * 
     * Parameters: 
     * e - {Event} 
     */
    onUpClick: function(e)
    {
        map.raiseLayer(this.layer, 1);  
        
        if (e != null) {
            OpenLayers.Event.stop(e);                                            
        }  
    },
    
     /**
     * Method: onTitleClick
     * Set the active layer
     * 
     * Parameters: 
     * e - {Event} 
     */
    onTitleClick: function(e) 
    {
        var id = this.layer.id;
       
        layerSwitcher.activeLayer = id;
        
        for (var i=0; i<map.layers.length;i++) { 
          var layer = map.layers[i]; 
          
          if(id == layer.id) {
            this.titleDiv.style.backgroundColor = "#999";
            this.titleDiv.style.border = "solid 1px #999";
          }
          else {           
            var div = OpenLayers.Util.getElement("title_" + layer.id); 
            
            if(div) { 
                div.style.backgroundColor = "#e1e1e1";
                div.style.border = "solid 1px #e1e1e1";
            }
          }           
        }        
        
        if (e != null) {
            OpenLayers.Event.stop(e);                                            
        }
    },
    
    toggleAbstract: function(e) 
    {        
        var span = OpenLayers.Util.getElement("abstract_" + this.layer.id);
        var button = this.button;
            
        if(span && button) { 
            var display = span.style.display;
            
            if(display == "block") {
                span.style.display = "none";
                button.src = OpenLayers.Util.getImagesLocation() + "expand.png";
                button.title = "Expand abstract";
            }
            else {
                span.style.display = "block";
                button.src = OpenLayers.Util.getImagesLocation() + "collapse.png";
                button.title = "Hide abstract";
            }
        }
        
    },
    
    /**
     * Method: onDataUrlClick
     * Open new window and redirect to URL.
     * 
     * Parameters: 
     * e - {Event} 
     *
     * Context:  
     *  - {string} url to redirect to
     */
    onDataUrlClick: function(e) 
    {    
        window.open(this.url , "data", "width=550,height=350,status=yes,scrollbars=yes,resizable=yes");
    },
    
    /**
     * Method: onMetadataUrlClick
     * Open new window and redirect to URL.
     * 
     * Parameters: 
     * e - {Event} 
     *
     * Context:  
     *  - {string} url to redirect to
     */
    onMetadataUrlClick: function(e) 
    {    
        window.open(this.url , "metadata", "width=550,height=350,status=yes,scrollbars=yes,resizable=yes");
    },
    
    /**
     * Method: onLayerClick
     * Need to update the map accordingly whenever user clicks in either of
     *     the layers.
     * 
     * Parameters: 
     * e - {Event} 
     */
    onLayerClick: function(e) {
        this.updateMap();
    },

    /**
     * Method: changeLayerOpacity
     * Changes opacity of a given layer for a given delta
     * 
     * Parameters: 
     * e - {Event} 
     *
     * Context:  
     *  - {string} amount to increase or decrease opacity value
     *  - {<OpenLayers.Layer>} layer
     *  - {<OpenLayers.Control.LayerSwitcher>} layerSwitcher
     */
    changeLayerOpacity: function(e) 
    {    
        var maxOpacity = 1.0;
        var minOpacity = 0.0;
        var opacity = (this.layer.opacity != null) ? this.layer.opacity : 1.0;
        var i = parseFloat(this.byOpacity);
        var opacityElement = "opacity_" + this.layer.id;  
        var opacityImg = "opacityImg_" + this.layer.id;
        var newOpacity = (parseFloat(opacity + i)).toFixed(1);
        
        newOpacity = Math.min(maxOpacity, Math.max(minOpacity, newOpacity));
        
        OpenLayers.Util.getElement(opacityElement).value = newOpacity;       
        OpenLayers.Util.getElement(opacityImg).width = (newOpacity * 23).toFixed(0);
        OpenLayers.Util.getElement(opacityImg).title = (newOpacity*100)+"% opacity";    
        
        this.layer.setOpacity(newOpacity);
    },

    /** 
     * Method: updateMap
     * Cycles through the loaded data and base layer input arrays and makes
     *     the necessary calls to the Map object such that that the map's 
     *     visual state corresponds to what the user has selected in 
     *     the control.
     */
    updateMap: function() 
    {
        // set the newly selected base layer        
        for(var i=0, len=this.baseLayers.length; i<len; i++) {
            var layerEntry = this.baseLayers[i];
            if (layerEntry.inputElem.checked) {
                this.map.setBaseLayer(layerEntry.layer, false);
            }
        }

        // set the correct visibilities for the overlays
        for(var i=0, len=this.dataLayers.length; i<len; i++) {
            var layerEntry = this.dataLayers[i];   
            layerEntry.layer.setVisibility(layerEntry.inputElem.checked);
        }
    },

    /** 
     * Method: maximizeControl
     * Set up the labels and divs for the control
     * 
     * Parameters:
     * e - {Event} 
     */
    maximizeControl: function(e) 
    {
        this.div.style.width = "200px";
        this.div.style.height = "100%";
        this.div.style.backgroundColor = "transparent";
        this.div.style.backgroundImage = "url("+OpenLayers.Util.getImagesLocation()+"1x1-75pc-opacity-dark.png)";
        this.div.style.backgroundRepeat = "repeat";

        this.showControls(false);

        if (e != null) {
            OpenLayers.Event.stop(e);                                            
        }
    },
    
    /** 
     * Method: minimizeControl
     * Hide all the contents of the control, shrink the size, 
     *     add the maximize icon
     *
     * Parameters:
     * e - {Event} 
     */
    minimizeControl: function(e) 
    {
        this.div.style.width = "0px";
        this.div.style.height = "100%";
        this.div.style.borderLeft = "none";

        this.showControls(true);

        if (e != null) {
            OpenLayers.Event.stop(e);                                            
        }
    },

    /**
     * Method: showControls
     * Hide/Show all LayerSwitcher controls depending on whether we are
     *     minimized or not
     * 
     * Parameters:
     * minimize - {Boolean}
     */
    showControls: function(minimize) {

        this.maximizeDiv.style.display = minimize ? "" : "none";
        this.minimizeDiv.style.display = minimize ? "none" : "";

        this.layersDiv.style.display = minimize ? "none" : "";
    },
    
    /** 
     * Method: loadContents
     * Set up the labels and divs for the control
     */
    loadContents: function() {

        //configure main div
        this.div.style.position = "absolute";
        this.div.style.top = "0px";
        this.div.style.right = "0px";
        this.div.style.left = "";
        this.div.style.fontFamily = "sans-serif";
        this.div.style.fontWeight = "bold";
        this.div.style.fontSize = "10px";  
        this.div.style.lineHeight = "1.2em"; 
        this.div.style.color = "#333";   
        this.div.style.backgroundColor = this.activeColor; 
        this.div.style.height = "100%";
    
        OpenLayers.Event.observe(this.div, "mouseup", 
            OpenLayers.Function.bindAsEventListener(this.mouseUp, this));
        OpenLayers.Event.observe(this.div, "click",
                      this.ignoreEvent);
        OpenLayers.Event.observe(this.div, "mousedown",
            OpenLayers.Function.bindAsEventListener(this.mouseDown, this));
        OpenLayers.Event.observe(this.div, "dblclick", this.ignoreEvent);

        // layers list div        
        this.layersDiv = document.createElement("div");
        this.layersDiv.setAttribute("className", "olLayerSwitcherLayerContainer");
        this.layersDiv.id = this.id + "_layersDiv";        
        this.layersDiv.style.overflowX = "hidden"; 
        this.layersDiv.style.overflowY = "scroll";
        this.layersDiv.style.position = "relative";
        this.layersDiv.style.height = "100%";        
        
        // ignore any mousewheel events
        OpenLayers.Event.observe(this.layersDiv, "mousewheel", this.ignoreEvent);

        // had to set width/height to get transparency in IE to work.
        // thanks -- http://jszen.blogspot.com/2005/04/ie6-opacity-filter-caveat.html
        
        this.baseLayersDiv = document.createElement("div"); 
        this.baseLayersTitleDiv = document.createElement("div");
        this.baseLayersTitleDiv.className = "olLayersTitle";
        this.baseLayersTitleDiv.innerHTML = "Base Layers";

        this.dataLayersDiv = document.createElement("div");
        this.dataLayersTitleDiv = document.createElement("div");
        this.dataLayersTitleDiv.className = "olLayersTitle";
        this.dataLayersTitleDiv.innerHTML = "Data Layers";

/*
        clearAllInput = document.createElement("input");
        clearAllInput.type = "button";
        clearAllInput.value = "Clear";
*/
        showAllInput = document.createElement("input");
        showAllInput.type = "button";
        showAllInput.value = "Show";
        hideAllInput = document.createElement("input");
        hideAllInput.type = "button";
        hideAllInput.value = "Hide";

/*
        function clearAllDataLayers(e, action) {
            var layer_count = this.map.getNumLayers();
            var current_index = 0;
            for (var i = 0; i < layer_count; i++) {
                layer = this.map.layers[current_index];
                if (layer && !layer.isBaseLayer) {
                    this.map.removeLayer(layer);
                } else {
                    current_index++;
                }
            } 

            if (e != null) {
                OpenLayers.Event.stop(e);
            }
        }

        OpenLayers.Event.observe(clearAllInput, "mouseup",
                    OpenLayers.Function.bindAsEventListener(clearAllDataLayers, this)
                );
 
        this.dataLayersTitleDiv.appendChild(clearAllInput);
*/
       
        if (this.ascending) {
            this.layersDiv.appendChild(this.baseLayersDiv);
            this.layersDiv.appendChild(this.dataLayersDiv);
        } else {
            this.layersDiv.appendChild(this.dataLayersDiv);
            this.layersDiv.appendChild(this.baseLayersDiv);
        }    

        
        this.div.appendChild(this.layersDiv);
        //OpenLayers.Rico.Corner.changeOpacity(this.layersDiv, 0.95);        
        
        var imgLocation = OpenLayers.Util.getImagesLocation();
        var sz = new OpenLayers.Size(20,60);        

        // maximize button div
        var img = imgLocation + 'layer-switcher-maximize.png';
        this.maximizeDiv = OpenLayers.Util.createAlphaImageDiv(
                                    "OpenLayers_Control_MaximizeDiv", 
                                    null, 
                                    sz, 
                                    img, 
                                    "absolute");
        this.maximizeDiv.style.top = "50%";
        this.maximizeDiv.style.marginTop = "-30px";
        this.maximizeDiv.style.right = "0px";
        this.maximizeDiv.style.left = "";
        this.maximizeDiv.style.display = "none";
        this.maximizeDiv.title = "Click to maximise layer list";
        OpenLayers.Event.observe(this.maximizeDiv, "click", 
            OpenLayers.Function.bindAsEventListener(this.maximizeControl, this)
        );
        
        this.div.appendChild(this.maximizeDiv);
        //OpenLayers.Rico.Corner.changeOpacity(this.maximizeDiv, 0.95);

        // minimize button div
        var img = imgLocation + 'layer-switcher-minimize.png';
        var sz = new OpenLayers.Size(20,60);        
        this.minimizeDiv = OpenLayers.Util.createAlphaImageDiv(
                                    "OpenLayers_Control_MinimizeDiv", 
                                    null, 
                                    sz, 
                                    img, 
                                    "absolute");
        this.minimizeDiv.style.top = "50%";
        this.minimizeDiv.style.marginTop = "-30px";
        this.minimizeDiv.style.right = "200px";
        this.minimizeDiv.style.left = "";
        this.minimizeDiv.title = "Click to minimise layer list";
        OpenLayers.Event.observe(this.minimizeDiv, "click", 
            OpenLayers.Function.bindAsEventListener(this.minimizeControl, this)
        );

        this.div.appendChild(this.minimizeDiv);
        //OpenLayers.Rico.Corner.changeOpacity(this.minimizeDiv, 0.95);
        
        
    },
    
    /** 
     * Method: ignoreEvent
     * 
     * Parameters:
     * evt - {Event} 
     */
    ignoreEvent: function(evt) {
        OpenLayers.Event.stop(evt);
    },

    /** 
     * Method: mouseDown
     * Register a local 'mouseDown' flag so that we'll know whether or not
     *     to ignore a mouseUp event
     * 
     * Parameters:
     * evt - {Event}
     */
    mouseDown: function(evt) {
        this.isMouseDown = true;
        this.ignoreEvent(evt);
    },

    /** 
     * Method: mouseUp
     * If the 'isMouseDown' flag has been set, that means that the drag was 
     *     started from within the LayerSwitcher control, and thus we can 
     *     ignore the mouseup. Otherwise, let the Event continue.
     *  
     * Parameters:
     * evt - {Event} 
     */
    mouseUp: function(evt) {
        if (this.isMouseDown) {
            this.isMouseDown = false;
            this.ignoreEvent(evt);
        }
    },
    
    CLASS_NAME: "OpenLayers.Control.ExtendedLayerSwitcher"
});

