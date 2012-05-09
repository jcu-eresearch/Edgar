<?php

    // change to the fullscreen layout
    $this->layout = 'fullscreencontent';


    // Inject javascript to specify species_id and map_tool_url.
//    $map_tool_url = $this->Html->url(array("controller" => "tools", "action" => "map"));
    $map_tool_base_url = "http://www.hpc.jcu.edu.au/tdh-tools-2:81/map_script/";
    $species_route_url = $this->Html->url(array("controller" => "species", "action" => "index"));
    if ($single_species_map) {
        $species_sci_name_cased = $species['Species']['scientific_name'];
        // Remove dots
        $species_sci_name_cased = preg_replace('/(\.)/', '', $species_sci_name_cased);
        // Remove leading and trailing space.
        $species_sci_name_cased = preg_replace('/(\s+)$/', '', $species_sci_name_cased);
        $species_sci_name_cased = preg_replace('/^(\s+)/', '', $species_sci_name_cased);
        // Replace remaining spaces with _
        $species_sci_name_cased = preg_replace('/(\s)/', '_', $species_sci_name_cased);

        $code_block =  "var species_id = '".$species['Species']['id']."';\n".
                       "var map_tool_base_url = '".$map_tool_base_url."';".
                       "var species_route_url= '".$species_route_url."';".
                       "var species_sci_name_cased = '".$species_sci_name_cased."';";
        echo $this->Html->scriptBlock($code_block, array('block' => 'script')); 
        echo $this->Html->script(array('species_map'), array('block' => 'script')); 
    } else {
        $code_block =  "var species_id = undefined;".
                       "var map_tool_base_url = '".$map_tool_base_url."';".
                       "var species_route_url= '".$species_route_url."';";
        // Include map javascript files
        echo $this->Html->scriptBlock($code_block, array('block' => 'script')); 
        echo $this->Html->script(array('species_map'), array('block' => 'script')); 
        echo $this->Html->script('clustering_selector_setup', array('inline'=>false)); 
    }

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

