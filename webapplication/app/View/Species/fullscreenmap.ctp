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
            . 'var mapToolBaseUrl = "http://www.hpc.jcu.edu.au/tdh-tools-2:80/Edgar/mapping/";';

    // add the init JS to our scripts content block
    $this->Html->scriptBlock($species_init_js, array('inline'=>false));

    // add more init stuff
    $this->Html->script('late_init_setup', array('inline'=>false));

    // add the actual JS that makes the map work
    $this->Html->script('species_map', array('inline'=>false));
    $this->Html->script('species_panel_setup', array('inline'=>false));
    $this->Html->script('yearslider', array('inline'=>false));
    $this->Html->script('clustering_selector_setup', array('inline'=>false));
    $this->Html->script('tabpanel_setup', array('inline'=>false));
    $this->Html->script('toolspanel_setup', array('inline'=>false));
    $this->Html->script('mapmodes', array('inline'=>false));
    $this->Html->script('vetting/vetting', array('inline'=>false));
    $this->Html->script('vetting/classify_habitat', array('inline'=>false));
    $this->Html->script('vetting/display_my_vettings', array('inline'=>false));
    $this->Html->script('vetting/display_their_vettings', array('inline'=>false));

    // the init stuff needs to go early
    $this->Html->script('init_setup', array('inline'=>false, 'block'=>'earlyscript'));
?>


<div id="debugpanel" class="opposite panel debugpanel">
</div>

<div id="toolspanel" class="side panel toolspanel">

    <div class="tool" id="oldvets">
        <h1>other people's vettings</h1>
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
        <h1>new vetting</h1>
        <div class="toolcontent">
            <div id="newvet_control" class="newvet_control">
                <button id="newvet_draw_polygon_button" class="ui-state-default ui-corner-all toggle draw_polygon" title="draw vetting polygons"><span class="ui-icon ui-icon-pencil"></span>Draw New Area</button>
                <button id="newvet_add_polygon_button" class="ui-state-default ui-corner-all non_toggle add_polygon" title="add new area"><span class="ui-icon ui-icon-circle-plus"></span>Add New Area</button>
                <button id="newvet_add_polygon_by_occurrences_button" class="ui-state-default ui-corner-all non_toggle add_polygon_by_occurrences" title="add area around occurrence clusters"><span class="ui-icon ui-icon-arrow-2-se-nw"></span>Add Areas Around Clusters</button>
                <button id="newvet_modify_polygon_button" class="ui-state-default ui-corner-all toggle modify_polygon" title="modify areas"><span class="ui-icon ui-icon-arrow-4"></span>Modify An Area</button>
                <button id="newvet_delete_selected_polygon_button" class="ui-state-default ui-corner-all non_toggle delete_selected_polygon ui-state-disabled" title="delete selected area" disabled=true><span class="ui-icon ui-icon-trash"></span>Delete Selected Area</button>
<!--                <button id="newvet_delete_all_polygons_button" class="ui-state-default ui-corner-all non_toggle delete_all_polygons" title="delete all areas"><span class="ui-icon ui-icon-trash"></span>Delete All Areas</button> -->
            </div>
            <!-- new vet form -->
            <form id="vetform">
                <legend>Classification
                    <select id="vetclassification" name="classification">
                        <option value="" selected=true>-- classify these areas --</option>
                        <option value="invalid">invalid</option>
                        <option value="historic">historic</option>
                        <option value="vagrant">vagrant</option>
                        <option value="irruptive">irruptive</option>
                        <option value="non-breeding">non-breeding</option>
                        <option value="breeding">breeding</option>
                        <option value="introduced breeding">introduced breeding</option>
                    </select>
                </legend>
                <legend>Comment
                    <textarea id="vetcomment" name="comment"></textarea>
                </legend>
            </form>
            <button id="vet_submit" class='ui-state-default ui-corner-all' title='save vetting'><span class="ui-icon ui-icon-disk"></span>Save this vetting</button>

            <div id="vethint" class="hint"></div>
        </div>
    </div>

    <div class="tool" id="tool-layers">
        <h1>showing on the map</h1>
        <div id="layerstool" class="toolcontent"></div>
    </div>

    <div class="tool legend startclosed" id="tool-legend">
        <h1>suitability legend</h1>
        <div class="toolcontent">
            <img id='map_legend_img' style='display:none;' src='' alt='map_legend'/>
        </div>
    </div>


    <div class="tool" id="tool-emissions">
        <h1>emissions and time</h1>
        <div class="toolcontent">
            <!-- the check box will probably be removed when this is working properly -->
            <input id="use_emission_and_year" type="checkbox" />
            <select id="emission_scenarios">
                <option value="sresa1b" selected="selected">sresa1b</option>
                <option value="sresb1">sresb1</option>
                <option value="sresa2">sresa2</option>
            </select>
            <span id="year_label"></span>
            <button id="play_slider_button">Play</button>
            <div id="year_slider"></div>
        </div>
    </div>

    <div class="tool startclosed" id="tool-debug">
        <h1>debug</h1>
        <div class="toolcontent">

            <hr style="clear: both">

            <!-- clustering selector -->
            <select id="cluster">
                <option value="dotradius" >Dot Radius (no clustering)</option>
                <option value="dotgrid" selected>Dot Grid</option>
                <option value="squaregrid">Square Grid</option>
            </select>

            <hr style="clear: both">

            <button id="vet">.vet.</button>
            <button id="devet">.devet.</button>
        </div>
    </div>

</div>

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


<!-- old species panel below -->

<!--
    <p class="minor label" id="species_modelling_status"></p>
    <p class="minor label" id="species_showing_label"></p>
-->
    <!-- Species Selector -->
<!--
    <input id="species_autocomplete" placeholder="Type species common/scientific name here" />

    <table>
        <tr>
            <th>Modeling Status</th>
            <td>
                <span id="model_status"></span>
                <span id="model_rerun" style="display:none">
                    <a id="model_rerun_button" href="#">Boost</a>
                    <span id="model_rerun_requested">Boost successfull</span>
                </span>
            </td>
        </tr>
    </table>
-->
</div>

<div id="map">
</div>

<div id="spinner"></div>

<div id="dialogs">
    <div id="discard-area-classifcation-confirm" title="Discard your area classification?" class="edgar-dialog">
        <p><span class="ui-icon ui-icon-alert" style="float:left; margin:0 7px 20px 0;"></span>The area classification you're working on will be permanently deleted and cannot be recovered. Are you sure?</p>
    </div>
</div>
