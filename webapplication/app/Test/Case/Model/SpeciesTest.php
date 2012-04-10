<?php
App::uses('Species', 'Model');

class SpeciesTestCase extends CakeTestCase {
    public $fixtures = array('app.species');

    public function setup() {
        parent::setUp();
        // From Cake PHP book:
        //
        // When setting up your Model for testing be sure to use ClassRegistry::init('YourModelName'); 
        // as it knows to use your test database connection.
        $this->Species = ClassRegistry::init('Species');
    }

    // Make sure that everything appears a-okay with the world
    public function testTrueIsIndeedTrue() {
        $this->assertEquals(true, true);
    }

    // This confirms that our setup did what we expect. This should never fail.
    public function testSpeciesIsIndeedSpecies() {
        $this->assertInstanceOf('Species', $this->Species);
    }
}
