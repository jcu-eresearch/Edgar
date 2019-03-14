<?php
    // change to the fullscreen layout
    $this->layout = 'fullscreencontent';

    // build some initialising JS
    $species_value = "null";
    if ($species !== null) {
        $species_value = json_encode($species);
    }
    $species_init_js =
            "var mapSpecies = " . $species_value . ";\n"
            . 'var mapToolBaseUrl = "http://tdh-tools-2.hpc.jcu.edu.au/Edgar/mapping/";';

    // add the init JS to our scripts content block
    $this->Html->scriptBlock($species_init_js, array('inline'=>false));

    // add more init stuff
    $this->Html->script('late_init_setup', array('inline'=>false));

    // add the actual JS that makes the map work
    $this->Html->script('species_map', array('inline'=>false));
    $this->Html->script('species_panel_setup', array('inline'=>false));
    $this->Html->script('clustering_selector_setup', array('inline'=>false));
    $this->Html->script('tabpanel_setup', array('inline'=>false));
    $this->Html->script('toolspanel_setup', array('inline'=>false));
    $this->Html->script('alertpanel_setup', array('inline'=>false));
    $this->Html->script('mapmodes', array('inline'=>false));
    $this->Html->script('future/yearslider', array('inline'=>false));
    $this->Html->script('future/future', array('inline'=>false));
    $this->Html->script('vetting/vetting', array('inline'=>false));
    $this->Html->script('vetting/classify_habitat', array('inline'=>false));
    $this->Html->script('vetting/display_my_vettings', array('inline'=>false));
    $this->Html->script('vetting/display_their_vettings', array('inline'=>false));
    $this->Html->script('templates/soyutils', array('inline'=>false));
    $this->Html->script('templates/detail_popup', array('inline'=>false));
    $this->Html->script('detail_popup', array('inline'=>false));

    // the init stuff needs to go early
    $this->Html->script('init_setup', array('inline'=>false, 'block'=>'earlyscript'));
?>


<div id="debugpanel" class="opposite panel debugpanel">
</div>

<div id="toolspanel" class="side panel toolspanel">

    <div class="tool" id="tool_modechanger">
        <h1>things to do</h1>
        <div class="toolcontent clearfix">

            <div id="modeswitches_nospecies">
                <p id="tip_no_species" class="tip">Start by entering a species.</p>
            </div>

            <div id="modeswitches">
                <button id="button_current" class="ui-state-default ui-corner-all">See current information</button>
                <button id="button_future" class="ui-state-default ui-corner-all">See future projections</button>
                <button id="button_vetting" class="ui-state-default ui-corner-all">Vet this species</button>
            </div>
        </div>

    </div>

    <div class="tool classlegend" id="tool_classlegend">
        <h1>classification legend</h1>
        <div class="toolcontent">
            <div class="classlist clearfix">
                <div class="leftcol">

                    <div class="classification" title="historic: observation in the past that does not represent modern presence of species">
                        <h2><span class="dot" style="background: #972"></span>historic</h2>
                    </div>
                    <div class="classification" title="irruptive: observation is in an irruptive range and does not represent continued presence of species">
                        <h2><span class="dot" style="background: #f6a"></span>irruptive</h2>
                    </div>
                    <div class="classification" title="vagrant: observation does not represent continued presence of species">
                        <h2><span class="dot" style="background: #f70"></span>vagrant</h2>
                    </div>
                    <div class="classification" title="core: observation is within a core range for species">
                        <h2><span class="dot" style="background: #02f"></span>core</h2>
                    </div>
                    <div class="classification" title="introduced: non-native core range">
                        <h2><span class="dot" style="background: #70f"></span>intro.</h2>
                    </div>
                </div>

                <div class="rightcol">
                    <div class="classification" title="unclassified: not yet classified (please vet!)">
                        <h2><span class="dot" style="background: #000"></span>unclassified</h2>
                    </div>
                    <div class="classification" title="doubtful: record is likely to be an error">
                        <h2><span class="dot" style="background: #c00"></span>doubtful</h2>
                    </div>
                    <div class="classification" style="visibility: hidden;">
                        <h2><span class="dot"></span>spacer</h2>
                    </div>
                    <div class="classification" title="this dot size indicates 10,000 observations">
                        <h2><span class="dot" style="left: -3px; top: -4px; background: #666; width: 23px; height: 23px"></span>10,000 obs.</h2>
                    </div>
                    <div class="classification" title="this dot size indicates 15 observations">
                        <h2><span class="dot" style="top: 2px; left: 3px; background: #666; width: 11px; height: 11px"></span>15 obs.</h2>
                    </div>
                </div>
            </div>
<!--
            <div class="classnesting clearfix">
                <p>Clusters show up to two classes:</p>
                <div class="classification" title="outer colour is the most common classification, inner colour the second most common">
                    <h2><span class="circle" style="background: #f70; border-color: #02f"></span>many core, some vagrant</h2>
                </div>

            </div>
-->
        </div>
    </div>


    <div class="tool simpleclasslegend" id="tool_simpleclasslegend">
        <h1>classification legend</h1>
        <div class="toolcontent">
            <div class="classlist clearfix">
                <div class="leftcol">

                    <div class="classification" title="historic: observation in the past that does not represent modern presence of species">
                        <h2><span class="dot" style="background: #972"></span>historic</h2>
                    </div>
                    <div class="classification" title="irruptive: observation is in an irruptive range and does not represent continued presence of species">
                        <h2><span class="dot" style="background: #f6a"></span>irruptive</h2>
                    </div>
                    <div class="classification" title="vagrant: observation does not represent continued presence of species">
                        <h2><span class="dot" style="background: #f70"></span>vagrant</h2>
                    </div>
                </div>

                <div class="rightcol">
                    <div class="classification" title="unclassified: not yet classified (please vet!)">
                        <h2><span class="dot" style="background: #000"></span>unclassified</h2>
                    </div>
                    <div class="classification" title="core: observation is within a core range for species">
                        <h2><span class="dot" style="background: #02f"></span>core</h2>
                    </div>
                    <div class="classification" title="introduced: non-native core range">
                        <h2><span class="dot" style="background: #70f"></span>introduced</h2>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <div class="tool legend" id="tool_legend">
        <h1>suitability legend</h1>
        <div class="toolcontent">
            <img id='map_legend_img' src=''/>
        </div>
    </div>

    <div class="tool" id="oldvets">
        <h1>other vettings</h1>
        <div class="toolcontent">
            <ul id="their_vettings_list" class="vetting_list theirs">
            </ul>
        </div>
    </div>

    <div class="tool" id="myvets">
        <h1>my vettings</h1>
        <div class="toolcontent">
            <ul id="my_vettings_list" class="vetting_list mine">
            </ul>
        </div>
    </div>

    <div class="tool" id="newvet">
        <h1>vet observations</h1>
        <div class="toolcontent">
            <div id="newvet_control" class="newvet_control">
<!--                <button id="newvet_draw_polygon_button" class="ui-state-default ui-corner-all toggle draw_polygon" title="draw vetting polygons"><span class="ui-icon ui-icon-pencil"></span>Draw New Area</button> -->
<!--                <button id="newvet_add_polygon_button" class="ui-state-default ui-corner-all non_toggle add_polygon" title="add new area"><span class="ui-icon ui-icon-circle-plus"></span>Add New Area</button> -->
                <button id="newvet_add_polygon_by_occurrences_button" class="ui-state-default ui-corner-all non_toggle add_polygon_by_occurrences" title="add area around occurrence clusters"><span class="ui-icon ui-icon-arrow-2-se-nw"></span>Select Observations</button>
<!--                <button id="newvet_modify_polygon_button" class="ui-state-default ui-corner-all toggle modify_polygon" title="modify areas"><span class="ui-icon ui-icon-arrow-4"></span>Modify An Area</button> -->
<!--                <button id="newvet_delete_selected_polygon_button" class="ui-state-default ui-corner-all non_toggle delete_selected_polygon ui-state-disabled" title="delete selected area" disabled=true><span class="ui-icon ui-icon-trash"></span>Delete Selected Area</button> -->
                <button id="newvet_delete_all_polygons_button" class="ui-state-default ui-corner-all non_toggle delete_all_polygons" title="clear selection"><span class="ui-icon ui-icon-trash"></span>Clear Selection</button>
            </div>
            <!-- new vet form -->
            <form id="vetform">
                <legend>Classification
                    <select id="vetclassification" name="classification">
                        <option value="" selected=true>-- classify as.. --</option>
                        <option value="invalid">doubtful</option>
                        <option value="historic">historical</option>
                        <option value="vagrant">vagrant</option>
                        <option value="irruptive">irruptive</option>
                        <option value="core">core</option>
                        <option value="introduced">introduced</option>
                    </select>
                </legend>
                <legend>Optional comment
                    <textarea id="vetcomment" name="comment"></textarea>
                </legend>
            </form>
            <button id="vet_submit" class='ui-state-default ui-corner-all' title='save vetting'><span class="ui-icon ui-icon-disk"></span>Save this Vetting</button>

            <div id="vethint" class="hint"></div>
        </div>
    </div>

    <div class="tool" id="tool_future">
        <h1>suitability projections</h1>
        <div class="toolcontent">
            <h3>Future Emission Scenario</h3>
            <label class="scenario ui-state-default ui-corner-all">
                <input type="radio" name="scenario" value="RCP85" checked="checked">
                <p>"Business as usual": increasing greenhouse gas emissions over time. (RCP8.5)</p>
            </label>
            <label class="scenario ui-state-default ui-corner-all">
                <input type="radio" name="scenario" value="RCP6">
                <p>Emissions stabilise some time after 2100. (RCP6)</p>
            </label>
            <label class="scenario ui-state-default ui-corner-all">
                <input type="radio" name="scenario" value="RCP45">
                <p>Emissions stabilise before 2100. (RCP4.5)</p>
            </label>
            <label class="scenario ui-state-default ui-corner-all">
                <input type="radio" name="scenario" value="RCP3PD">
                <p>Emissions reduce substantially. (RCP2.6)</p>
            </label>

            <div class="loading_container" style="display: none;">
                Loading projection maps...
                <div class="loading_bar"></div>
            </div>
            <div class="options_container">
                <div class="sliderbox">
                    <span id="year_label"></span>
                    <button id="play_slider_button" class="ui-state-default ui-corner-all ui-icon ui-icon-play">play</button>
                    <div id="year_slider"></div>
                </div>
            </div>
        </div>
    </div>

    <div class="tool" id="tool_layers">
        <h1>showing on the map</h1>
        <div id="layerstool" class="toolcontent"></div>
    </div>

    <div class="tool startclosed" id="tool_specieslinks">
        <h1>downloadable data</h1>
        <div class="toolcontent">

            <div id="downloadables">
                For this species:
                <button id="btn_species_occur" class="downloadbtn ui-button ui-button-text-only ui-widget ui-state-default ui-corner-all">Observations</button>
                <button id="btn_species_clim" class="downloadbtn ui-button ui-button-text-only ui-widget ui-state-default ui-corner-all">Projected distributions</button>
            </div>

            <div id="nodownloadables">
                Downloadable files are created when the species is modelled.  No downloads are currently available for this species.
            </div>

        </div>
    </div>

    <div class="tool startclosed" id="tool_debug">
        <h1>debug</h1>
        <div class="toolcontent">

            <hr style="clear: both">

            <!-- clustering selector -->
            Clustering..
            <select id="cluster" style="width: 80%">
                <option value="dotradius" >Dot Radius (no clustering)</option>
                <option value="dotgrid">Dot Grid</option>
                <option value="dotgriddetail">Dot Grid Detail</option>
                <option value="dotgridsimple" selected="selected">Dot Grid Simple</option>
                <option value="dotgridtrump">Dot Grid Trump</option>
                <option value="squaregrid">Square Grid</option>
            </select>

            <hr style="clear: both">

        </div>
    </div>

</div><!-- end of tools panel -->

<div id="speciespanel" class="top panel speciespanel clearfix">

    <div id="currentspecies">
        <div class="speciesname">
            <h1><span style="opacity: 0.2">(No Common Name)</span></h1>
            <h2><span style="opacity: 0.2">Scientific species name</span></h2>
            <button id="button_changespecies" class="changebtn ui-state-default ui-corner-all">change<br>species</button>
        </div>
        <div class="speciesinfo">
            <p class="status"></p>
            <button id="button_remodel" class="button-remodel ui-state-default ui-corner-all">request modelling</button>
        </div>
    </div>

    <div id="speciesselector">
        <input id="species_autocomplete" placeholder="Type species common/scientific name here" />
        <button id="button_cancelselect" class="button-cancelselect ui-state-default ui-corner-all">cancel</button>
    </div>

</div>

<div id="alertpanel" class="bottom panel float alertpanel clearfix"><div>
    <button class="closebutton">&#x2716;</button>
    <p>
        <b style="color: #222">We apologise</b> but due to <a target="_blank" href="http://www.jcu.edu.au/archives/centralcomputing/msg02624.shtml">hardware failures</a> at James Cook University's High Performance Computing facility, current and future distribution maps are temporarily not available.  A resolution time <a target="_blank" href="http://www.jcu.edu.au/archives/centralcomputing/msg02625.shtml">has not been determined</a>.
    </p><p>
        This will prevent display of the suitability legend and Climate Suitability map in current mode, and future mode will appear blank.
    </p>
</div></div>

<div id="map">
</div>

<div id="spinner"></div>

<div id="dialogs">
    <div id="discard-area-classifcation-confirm" title="Discard your area classification?" class="edgar-dialog">
        <p><span class="ui-icon ui-icon-alert" style="float:left; margin:0 7px 20px 0;"></span>The area classification you're working on will be permanently deleted and cannot be recovered. Are you sure?</p>
    </div>
</div>
