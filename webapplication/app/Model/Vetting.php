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

    public function getPropertiesJSONString($classification) {
        switch($classification) {
            case "unknown":
                return '"properties": {'.
                        '"fill_color": "#00FFFF",'.
                        '"stroke_color": "#FF0000",'.
                        '"font_color": "#FF0000",'.
                        '"label":"'.$classification.'"'.
                    '}';
                break;
            case "invalid":
                return '"properties": {'.
                        '"fill_color": "#AACCFF",'.
                        '"stroke_color": "#339900",'.
                        '"font_color": "#339900",'.
                        '"label":"'.$classification.'"'.
                    '}';
                break;
            case "historic":
                return '"properties": {'.
                        '"fill_color": "#FF9999",'.
                        '"stroke_color": "#AA0000",'.
                        '"font_color": "#AA0000",'.
                        '"label":"'.$classification.'"'.
                    '}';
                break;
            case "vagrant":
                return '"properties": {'.
                        '"fill_color": "#FFC0FF",'.
                        '"stroke_color": "#0000AA",'.
                        '"font_color": "#0000AA",'.
                        '"label":"'.$classification.'"'.
                    '}';
                break;
            case "irruptive":
                return '"properties": {'.
                        '"fill_color": "#99CAFF",'.
                        '"stroke_color": "#AA2200",'.
                        '"font_color": "#AA2200",'.
                        '"label":"'.$classification.'"'.
                    '}';
                break;
            case "non-breeding":
                return '"properties": {'.
                        '"fill_color": "#FFFF33",'.
                        '"stroke_color": "#003300",'.
                        '"font_color": "#003300",'.
                        '"label":"'.$classification.'"'.
                    '}';
                break;
            case "introduced non-breeding":
                return '"properties": {'.
                        '"fill_color": "#AA3399",'.
                        '"stroke_color": "#AAAAAA",'.
                        '"font_color": "#AAAAAA",'.
                        '"label":"'.$classification.'"'.
                    '}';
                break;
            case "breeding":
                return '"properties": {'.
                        '"fill_color": "#FFCC00",'.
                        '"stroke_color": "#CC0000",'.
                        '"font_color": "#CC0000",'.
                        '"label":"'.$classification.'"'.
                    '}';
                break;
            case "introduced breeding":
                return '"properties": {'.
                        '"fill_color": "#FF3399",'.
                        '"stroke_color": "#990000",'.
                        '"font_color": "#990000",'.
                        '"label":"'.$classification.'"'.
                    '}';
                break;
            default:
                return '"properties": {'.
                        '"fill_color": "#FFFFFF",'.
                        '"stroke_color": "#000000",'.
                        '"font_color": "#000000",'.
                        '"label":"'.$classification.'"'.
                    '}';
                break;
        }
    }
}
