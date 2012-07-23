SELECT classification,
  round(CAST (ST_X(location) as numeric), 1) as longitude,
  round(CAST (ST_Y(location) as numeric), 1) as latitude,
  COUNT(*)
FROM occurrences
WHERE
  species_id = 1            -- the species to group classifications for
GROUP BY classification, longitude, latitude
;
