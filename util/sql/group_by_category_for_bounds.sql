SELECT classification as latitude, COUNT(*)
FROM occurrences
WHERE
  species_id = 1              -- the species to group classifications for
  AND ST_X(location) > 140    -- min longitude
  AND ST_X(location) <= 155   -- max longitude
  AND ST_Y(location) > -25    -- min longitude
  AND ST_Y(location) <= -10   -- max longitude
GROUP BY classification
;
