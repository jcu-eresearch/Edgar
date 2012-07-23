-- Get the Longitude and Latitude of all occurrences for a species

SELECT ST_X(location) as longitude, ST_Y(location) as latitude FROM occurrences
WHERE species_id = 1  -- the species to look at
;
