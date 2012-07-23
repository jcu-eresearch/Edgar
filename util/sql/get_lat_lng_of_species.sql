-- Setup Globals
--
-- The species to run this command on.
\set species_id_var 1;

-- Get the Longitude and Latitude of a species
SELECT ST_X(location) as longitude, ST_Y(location) as latitude FROM occurrences WHERE species_id = :species_id_var;
