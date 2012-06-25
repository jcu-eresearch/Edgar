<?php

// File: app/Model/Vetting.rb
class Vetting extends AppModel {
    public $name = 'Vetting';

    public $belongsTo = array(
        'User' => array(
            'className' => 'User',
            'foreignKey' => 'user_id'
        ),
        'Species' => array(
            'className' => 'Species',
            'foreignKey' => 'species_id'
        )
    );

    public function getPropertiesJSONString($classification, $comment) {
        $fill_color  = null;
        $stroke_color= null;
        $font_color  = null;

        switch($classification) {
            case "unknown":
                $fill_color   = "#00FFFF";
                $stroke_color = "#FF0000";
                $font_color   = $fill_color;
                break;
            case "invalid":
                $fill_color   = "#AACCFF";
                $stroke_color = "#339900";
                $font_color   = $fill_color;
                break;
            case "historic":
                $fill_color   = "#FF9999";
                $stroke_color = "#AA0000";
                $font_color   = $fill_color;
                break;
            case "vagrant":
                $fill_color   = "#FFC0FF";
                $stroke_color = "#0000AA";
                $font_color   = $fill_color;
                break;
            case "irruptive":
                $fill_color   = "#99CAFF";
                $stroke_color = "#AA2200";
                $font_color   = $fill_color;
                break;
            case "non-breeding":
                $fill_color   = "#FFFF33";
                $stroke_color = "#003300";
                $font_color   = $fill_color;
                break;
            case "introduced non-breeding":
                $fill_color   = "#AA3399";
                $stroke_color = "#AAAAAA";
                $font_color   = $fill_color;
                break;
            case "breeding":
                $fill_color   = "#FFCC00";
                $stroke_color = "#CC0000";
                $font_color   = $fill_color;
                break;
            case "introduced breeding":
                $fill_color   = "#FF3399";
                $stroke_color = "#990000";
                $font_color   = $fill_color;
                break;
            default:
                $fill_color   = "#FFFFFF";
                $stroke_color = "#000000";
                $font_color   = $fill_color;
                break;
        }
        return  '"properties": {'.
                '"fill_color": "'.$fill_color.'",'.
                '"stroke_color": "'.$stroke_color.'",'.
                '"font_color": "'.$font_color.'",'.
                '"label":"'.$classification.'",'.
                '"comment":"'.$comment.'"'.
            '}';
    }
}
