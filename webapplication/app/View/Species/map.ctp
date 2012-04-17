<?php
    // Inject javascript to specify species_id and map_tool_url.
    $map_tool_url = $this->Html->url(array("controller" => "tools", "action" => "map"));
    $species_route_url = $this->Html->url(array("controller" => "species", "action" => "index"));
    if ($single_species_map) {
        $code_block =  "var species_id = '".$species['Species']['id']."';\n".
                       "var map_tool_url = '".$map_tool_url."';".
                       "var species_route_url= '".$species_route_url."';";
        echo $this->Html->scriptBlock($code_block, array('block' => 'script')); 
        echo $this->Html->script(array('species_map'), array('block' => 'script')); 
    } else {
        $code_block =  "var species_id = undefined;".
                       "var map_tool_url = '".$map_tool_url."';".
                       "var species_route_url= '".$species_route_url."';";
        // Include map javascript files
        echo $this->Html->scriptBlock($code_block, array('block' => 'script')); 
        echo $this->Html->script(array('species_map'), array('block' => 'script')); 
    }

?>

<div class="species map">
<h2><?php  echo __('Species Map');?></h2>

<?php
    if ($single_species_map) {
?>
<!-- Map Specific For Species -->
    <dl>
        <dt><?php echo __('Id'); ?></dt>
        <dd>
            <?php echo h($species['Species']['id']); ?>
            &nbsp;
        </dd>
        <dt><?php echo __('Scientific Name'); ?></dt>
        <dd>
            <?php echo h($species['Species']['scientific_name']); ?>
            &nbsp;
        </dd>
        <dt><?php echo __('Common Name'); ?></dt>
        <dd>
            <?php echo h($species['Species']['common_name']); ?>
            &nbsp;
        </dd>
    </dl>

<?php
    } else {
?>
    <!-- Species Selector -->
    <?php
        echo $this->Form->create('Species', array(
            'type' => 'get',
            'action' => 'map'
        ));
    ?>
        <?php
            echo $this->Form->input('species_id', array('empty' => '(choose one)'));
        ?>
    <?php echo $this->Form->end();?>
<?php
    }
?>
    <div style="width:60em; height: 40em;" id="map"></div>
</div>
