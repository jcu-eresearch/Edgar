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

    // add the actual JS that makes the map work
    $this->Html->script('species_map', array('inline'=>false));
    $this->Html->script('species_panel_setup', array('inline'=>false));
    $this->Html->script('yearslider', array('inline'=>false));
    $this->Html->script('clustering_selector_setup', array('inline'=>false));
    $this->Html->script('tabpanel_setup', array('inline'=>false));
    $this->Html->script('toolspanel_setup', array('inline'=>false));
    $this->Html->script('vetting', array('inline'=>false));

    // the init stuff needs to go early
    $this->Html->script('init_setup', array('inline'=>false, 'block'=>'earlyscript'));

?>


<div id="debugpanel" class="opposite panel debugpanel">
</div>

<div id="toolspanel" class="side panel toolspanel">

    <div id="oldvets" class="tool">
        <h1>my previous vettings</h1>
        <div class="toolcontent">
            <form id="vetlist">
                list of old vets goes here
            </form>
        </div>
    </div>

    <div id="newvet" class="tool">
        <h1>new vetting</h1>
        <div class="toolcontent">
            <div id="newvet_control" class="newvet_control">
                <!-- <button id="newvet_draw_polygon_button" class="toggle draw_polygon" title="draw vetting polygons">&#9997; Draw Vetting Polygons</button> -->
                <button id="newvet_add_polygon_button" class="ui-state-default ui-corner-all non_toggle add_polygon" title="add new area"><span class="ui-icon ui-icon-circle-plus"></span>Add New Area</button>
                <button id="newvet_modify_polygon_button" class="ui-state-default ui-corner-all toggle modify_polygon" title="modify area"><span class="ui-icon ui-icon-pencil"></span>Modify An Area</button>
                <button id="newvet_clear_polygon_button" class="ui-state-default ui-corner-all non_toggle clear_polygon" title="clear area"><span class="ui-icon ui-icon-trash"></span>Clear All Areas</button>
            </div>
            <!-- new vet form -->
            <form id="vetform">
                <legend>Classification
                    <select id="vetclassification" name="classification">
                        <option value="" selected=true>-- classify these areas --</option>
                        <option value="unknown">unknown</option>
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
                <button id="vet_submit" class='ui-state-default ui-corner-all'><span class="ui-icon ui-icon-disk"></span>Save this vetting</button>
            </form>

            <div id="vethint" class="hint"></div>
        </div>
    </div>

    <div class="tool">
        <h1>showing on the map</h1>
        <div id="layerstool" class="toolcontent"></div>
    </div>

    <div class="tool">
        <h1>some tool</h1>
        <div class="toolcontent">
            tool content goes here
        </div>
    </div>

    <div class="tool legend startclosed">
        <h1>suitability legend</h1>
        <div class="toolcontent">
            <img id='map_legend_img' style='display:none;' src='' alt='map_legend'/>
        </div>
    </div>


    <div class="tool">
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
            <div id="year_slider"></div>
        </div>
    </div>

    <div class="tool">
        <h1>debug</h1>
        <div class="toolcontent">

            <!-- clustering selector -->
            <fieldset class="clusteroptions" style="float: right">
                <legend>Clustering Display</legend>
                <select id="cluster">
                    <option value="dotradius" >Dot Radius (no clustering)</option>
                    <option value="dotgrid" selected>Dot Grid</option>
                    <option value="squaregrid">Square Grid</option>
                </select>
            </fieldset>

            <hr style="clear: both">

            <button id="go">.go.</button>
            <label><input id="done" type="checkbox" value="done" />done</label>
        </div>
    </div>

</div>

<div id="speciespanel" class="top panel speciespanel clearfix">

    <p class="minor label" id="species_modelling_status"></p>
    <p class="minor label" id="species_showing_label"></p>

    <!-- Species Selector -->
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
</div>

<div id="map">
</div>

<div id="spinner"></div>

