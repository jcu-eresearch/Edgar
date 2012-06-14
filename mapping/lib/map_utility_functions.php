<?php

// Removes all style classes from the layer.
function mu_removeAllStyleClasses($layer)
{
    // Pull out every class in the map file.
    while($layer->removeClass(0) != NULL);
}

?>
