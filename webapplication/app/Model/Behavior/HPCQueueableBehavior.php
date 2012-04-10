<?php
/**
 * HPCQueueableBehavior provides...
 */
class HPCQueueableBehavior extends ModelBehavior {
    /**
     * Store the settings for this model.
     */
    public function setup($Model, $config = array()) {
        $settings = $config;
        $this->settings[$Model->alias] = $settings;
    }
}
