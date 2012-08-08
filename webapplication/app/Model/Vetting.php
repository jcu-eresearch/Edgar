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

    public function getPropertiesJSONObject($classification) {
        $fill_color  = null;
        $stroke_color= null;
        $font_color  = null;

        switch($classification) {
            case "unknown":
                $fill_color   = "#000000";
                $stroke_color = $fill_color;
                $font_color   = $stroke_color;
                break;
            case "invalid":
                $fill_color   = "#cc0000";
                $stroke_color = $fill_color;
                $font_color   = $stroke_color;
                break;
            case "historic":
                $fill_color   = "#997722";
                $stroke_color = $fill_color;
                $font_color   = $stroke_color;
                break;
            case "vagrant":
                $fill_color   = "#ff7700";
                $stroke_color = $fill_color;
                $font_color   = $stroke_color;
                break;
            case "irruptive":
                $fill_color   = "#ff66aa";
                $stroke_color = $fill_color;
                $font_color   = $stroke_color;
                break;
/*
            case "non-breeding":
                $fill_color   = "#7700ff";
                $stroke_color = $fill_color;
                $font_color   = $stroke_color;
                break;
            case "introduced non-breeding":
                $fill_color   = "#bb33ff";
                $stroke_color = $fill_color;
                $font_color   = $stroke_color;
                break;
            case "breeding":
                $fill_color   = "#0022ff";
                $stroke_color = $fill_color;
                $font_color   = $stroke_color;
                break;
            case "introduced breeding":
                $fill_color   = "#2266ff";
                $stroke_color = $fill_color;
                $font_color   = $stroke_color;
                break;
*/
            case "core":
                $fill_color   = "#0022ff";
                $stroke_color = $fill_color;
                $font_color   = $stroke_color;
                break;

            case "other": // is a consolidation of historic, vagrant, and irruptive
                $fill_color   = "#ff7700";
                $stroke_color = $fill_color;
                $font_color   = $stroke_color;
                break;

            default:
                $fill_color   = "#ffffff";
                $stroke_color = $fill_color;
                $font_color   = $stroke_color;
                break;
        }
        $json_array =  array(
            'fill_color'     => $fill_color,
            'stroke_color'   => $stroke_color,
            'font_color'     => $font_color,
            'classification' => $classification,
        );
        return $json_array;
    }

}
