SELECT
  round(CAST (ST_X(location) as numeric), 0) as longitude,
  round(CAST (ST_Y(location) as numeric), 0) as latitude,
  sum(case when classification = 'unknown' then 1 else 0 end) as unkown_count,
  sum(case when classification = 'invalid' then 1 else 0 end) as invalid_count,
  COUNT(*)
FROM occurrences
WHERE
  species_id = 1              -- the species to group classifications for
  AND ST_X(location) > 140    -- min longitude
  AND ST_X(location) <= 155   -- max longitude
  AND ST_Y(location) > -25    -- min longitude
  AND ST_Y(location) <= -10   -- max longitude
GROUP BY longitude, latitude
;
