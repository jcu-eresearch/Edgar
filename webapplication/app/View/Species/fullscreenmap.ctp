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
            . 'var mapToolBaseUrl = "http://www.hpc.jcu.edu.au/tdh-tools-2:81/map_script/";';

    // add the init JS to our scripts content block
    $this->Html->scriptBlock($species_init_js, array('inline'=>false));
    
    // add the actual JS that makes the map work
    $this->Html->script('species_map', array('inline'=>false));
    $this->Html->script('species_panel_setup', array('inline'=>false));
    $this->Html->script('clustering_selector_setup', array('inline'=>false));
    $this->Html->script('toolspanel_setup', array('inline'=>false));
?>


<div id="debugpanel" class="opposite panel debugpanel">
    <!-- clustering selector -->
    <fieldset class="clusteroptions" style="float: right">
        <legend>Clustering Display</legend>
        <select id="cluster">
            <option value="dotradius" >Dot Radius (no clustering)</option>
            <option value="dotgrid" selected>Dot Grid</option>
            <option value="squaregrid">Square Grid</option>
        </select>
    </fieldset>
</div>

<div id="toolspanel" class="side panel toolspanel">
    <!-- things here -->    
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
    <div class="tool">
        <h1>another tool</h1>
        <div class="toolcontent">
            tool content goes here
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

<div id="map"></div>

