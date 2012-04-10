<?php
// Fixture for testing Species
class SpeciesFixture extends CakeTestFixture {
    // Import model information and records from 'default' database.
    //
    // NOTE: We are importing the records from our 'default' database into our
    //       'test' database.
    //       Some code describing how to manually define fixture records can be
    //       be found below.
    public $import = array(
        'model' => 'Species',
        'records' => true
    );

// If we don't want to pull our fixture records from the 'default' database,
// we can instead set records to false in the above import, and then uncomment
// the code below. Note, it will be neccessary to set the additional fields
// found in our Species Model.
//
//    Setup some dummy records
//    public $records = array(
//        array('id' => 1, 'name' => 'emu', 'created' => '2007-03-18 10:39:23', 'modified' => '2007-03-18 10:41:31'),
//        array('id' => 2, 'name' => 'crow', 'created' => '2007-03-19 10:39:23', 'modified' => '2007-03-20 10:41:31')
//    );
}
