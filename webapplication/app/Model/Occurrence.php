<?php

// File: app/Model/Occurrence.php
// Author: Robert Pyke

class Occurrence extends AppModel {
    public $name = 'Occurrence';
    public $belongsTo = 'Species';
}
