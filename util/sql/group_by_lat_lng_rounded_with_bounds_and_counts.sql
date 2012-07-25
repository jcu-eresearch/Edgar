SELECT
  round(CAST (ST_X(location) as numeric), 0) as longitude,
  round(CAST (ST_Y(location) as numeric), 0) as latitude,
  sum(case when classification = 'unknown' then 1 else 0 end) as unknown_count,
  sum(case when classification = 'invalid' then 1 else 0 end) as invalid_count,
  sum(case when classification = 'historic' then 1 else 0 end) as historic_count,
  sum(case when classification = 'vagrant' then 1 else 0 end) as vagrant_count,
  sum(case when classification = 'irruptive' then 1 else 0 end) as irruptive_count,
  sum(case when classification = 'non-breeding' then 1 else 0 end) as non_breeding_count,
  sum(case when classification = 'introduced non-breeding' then 1 else 0 end) as introduced_non_breeding_count,
  sum(case when classification = 'breeding' then 1 else 0 end) as breeding_count,
  sum(case when classification = 'introduced breeding' then 1 else 0 end) as introduced_breeding_count,
  COUNT(*)
FROM occurrences
WHERE
  species_id = 1              -- the species to group classifications for
  AND ST_X(location) > 120    -- min longitude
  AND ST_X(location) <= 175   -- max longitude
  AND ST_Y(location) > -35    -- min longitude
  AND ST_Y(location) <= -05   -- max longitude
GROUP BY longitude, latitude
;
