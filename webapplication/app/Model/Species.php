<?php

// File: app/Model/Species.rb
class Species extends AppModel {
    public $name = 'Species';

    // Define behaviours
    public $actsAs = array(
        'HPCQueueable' => array()
    );
}
