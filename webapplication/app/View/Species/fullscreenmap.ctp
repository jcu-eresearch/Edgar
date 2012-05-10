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
    $this->Html->script('clustering_selector_setup', array('inline'=>false));
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
        <h1>some tool</h1>
        <div class="toolcontent">
            tool content goes here
        </div>
    </div>
</div>

<div id="speciespanel" class="top panel speciespanel">
    <div id="model_rerun">
        <a id="model_rerun_button" href="#">Request recalculation of distribution map</a>
        <p id="model_rerun_requested">Request successful</p>
    </div>

    <!-- Species Selector -->
    <input id="species_autocomplete" placeholder="Type species common/scientific name here" />
</div>

<div id="map"></div>

