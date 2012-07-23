SELECT classification as latitude, COUNT(*)
FROM occurrences
WHERE
  species_id = 1            -- the species to group classifications for
GROUP BY classification
;
