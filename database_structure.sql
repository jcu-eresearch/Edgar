-- SQL compatible with PostgreSQL v8.4 + PostGIS 1.5




-- ////////////////////////////////////////////////////////////////////////////////////////////////////
-- CUSTOM TYPES
-- ////////////////////////////////////////////////////////////////////////////////////////////////////

-- The ratings enum has these values, in order:
--     "unknown" - lolwut i don't even
--     "invalid" - nope, you didn't see the bird here
--     "historic" - bird was there when you saw it in 1960, but they don't live there now
--     "vagrant" - bird might have been seen there, bit it doesn't actually live there/can't survive there
--     "irruptive" - bird sometimes lives there, like when there's a mouse plague or something, but it's not a persistent habitat
--     "non-breeding" - bird lives there, some or most of the year, but it's migratory and doesn't breed there
--     "introduced non-breeding" - a theoretical classification that's like non-breeding, but it was introduced to the habitat by humans
--     "breeding" - bird lives there, some or all of the year, and breeds there
--     "introduced breeding" - like breeding, but it was introduced to the habitat by humans
--
-- The occurrence should be used in modelling if the rating is "irruptive" or better.

CREATE TYPE rating AS ENUM(
    'unknown',
    'invalid',
    'historic',
    'vagrant',
    'irruptive',
    'non-breeding',
    'introduced non-breeding',
    'breeding',
    'introduced breeding'
);



-- ////////////////////////////////////////////////////////////////////////////////////////////////////
-- TABLE DEFINITIONS
-- ////////////////////////////////////////////////////////////////////////////////////////////////////

-- Each species has many occurrences, and each occurrence belongs to one species.
CREATE TABLE species (
    id SERIAL NOT NULL PRIMARY KEY,
    scientific_name VARCHAR(256) NOT NULL, -- Format: Genus (subgenus) species
    common_name VARCHAR(256) NULL, -- Some species don't have a common name (can be null)
    num_dirty_occurrences INT DEFAULT 0 NOT NULL, -- This is the number of occurrences that have changed since the last modelling run happened
    distribution_threshold FLOAT DEFAULT 0 NOT NULL, -- the Equate entropy of thresholded and original distributions logistic threshold found in the model output
    first_requested_remodel TIMESTAMP DEFAULT NULL NULL, -- The first time, since last modelling run, that a user requested a remodel for this species
    remodel_status VARCHAR(256) DEFAULT NULL NULL -- NULL if no modeling run is happening for this species, otherwise a message indicating the status of the modeling run
);


-- Each row represents a data source of occurrences (e.g. ALA).
-- Each source has many occurrences, and each occurrence belongs to one source.
CREATE TABLE sources (
    id SERIAL NOT NULL PRIMARY KEY,
    name VARCHAR(256) NOT NULL, -- arbitrary human-readble identifier for the source
    last_import_time TIMESTAMP NULL -- the last time data was imported from this source
);


-- Each row is an occurrence record.
--
-- This table will hold around 16 million occurrences from ALA alone,
-- so it should have as few columns as possible.
CREATE TABLE occurrences (
    id SERIAL NOT NULL PRIMARY KEY,
    rating rating NOT NULL, -- The canonical rating (a.k.a "vetting") for the occurrence
    species_id INT NOT NULL, -- foreign key to species.id
    source_id INT NOT NULL, -- foreign key to sources.id
    source_record_id bytea NULL, -- the id of the record as obtained from the source (e.g. the uuid from ALA)
    source_rating rating NOT NULL -- The rating as obtained from the source (i.e. ALA assertions translated to our ratings system)
);
SELECT AddGeometryColumn('occurrences', 'location', 4326, 'POINT', 2);
ALTER TABLE occurrences ALTER COLUMN location SET NOT NULL;
CREATE INDEX occurrences_species_id_idx ON occurrences (species_id);
CREATE UNIQUE INDEX occurrences_source_record_idx ON occurrences (source_id, source_record_id);
CREATE INDEX occurrences_location_idx ON occurrences USING GIST (location);
-- Do this manually, can take hours: CLUSTER occurrences USING occurrences_location_idx;
VACUUM ANALYSE occurrences;


-- SHOULD NOT BE ACCESSABLE TO THE PUBLIC.
-- Join this table to the occurrences table for access to the sensitive_location
CREATE TABLE sensitive_occurrences (
    occurrence_id INT NOT NULL REFERENCES occurrences(id) ON DELETE CASCADE -- foreign key to occurrences.id
);
SELECT AddGeometryColumn('sensitive_occurrences', 'sensitive_location', 4326, 'POINT', 2);
ALTER TABLE sensitive_occurrences ALTER COLUMN sensitive_location SET NOT NULL;
CREATE UNIQUE INDEX sensitive_occurrences_occurrence_id_idx ON sensitive_occurrences (occurrence_id);


-- No passwords for users because ALA handles the auth
CREATE TABLE users (
    id SERIAL NOT NULL PRIMARY KEY,
    email VARCHAR(256) NOT NULL,
    fname VARCHAR(256) NOT NULL,
    lname VARCHAR(256) NOT NULL,
    can_rate BOOLEAN DEFAULT TRUE NOT NULL,
    is_admin BOOLEAN DEFAULT FALSE NOT NULL
);


-- These are the user ratings (a.k.a vetting information) for
-- occurrences. Each row is arbitrary area to which a specific rating enum
-- value applies, by a single user for a single species. ALA has a system of
-- "assertions" that doesn't match up very will to the way we will be rating
-- occurrences.
CREATE TABLE ratings (
    id SERIAL NOT NULL PRIMARY KEY,
    user_id INT NOT NULL, -- foreign key into users.id
    species_id INT NOT NULL, -- foreign key into species.id
    comment TEXT NOT NULL, -- additional free-form comment supplied by the user
    rating rating NOT NULL
);
SELECT AddGeometryColumn('ratings', 'area', 4326, 'MULTIPOLYGON', 2);
ALTER TABLE ratings ALTER COLUMN area SET NOT NULL;
ALTER TABLE ratings ADD CONSTRAINT ratings_area_valid_check CHECK (ST_IsValid(area));




-- ////////////////////////////////////////////////////////////////////////////////////////////////////
-- PERMISSIONS
-- ////////////////////////////////////////////////////////////////////////////////////////////////////
-- Assumes that there are two users/roles: edgar_frontend and edgar_backend.
-- Also assumes this SQL is running with grant privileges

-- edgar_backend
GRANT SELECT, INSERT, UPDATE, DELETE ON species TO edgar_backend;
GRANT SELECT, INSERT, UPDATE, DELETE ON sources TO edgar_backend;
GRANT SELECT, INSERT, UPDATE, DELETE ON occurrences TO edgar_backend;
GRANT SELECT, INSERT, UPDATE, DELETE ON sensitive_occurrences TO edgar_backend;
GRANT SELECT, INSERT, UPDATE, DELETE ON ratings TO edgar_backend;
GRANT USAGE, SELECT ON species_id_seq TO edgar_backend;
GRANT USAGE, SELECT ON sources_id_seq TO edgar_backend;
GRANT USAGE, SELECT ON occurrences_id_seq TO edgar_backend;
GRANT USAGE, SELECT ON ratings_id_seq TO edgar_backend;

-- edgar_frontend
GRANT SELECT ON species TO edgar_frontend;
GRANT SELECT ON occurrences TO edgar_frontend;
GRANT SELECT, INSERT ON ratings TO edgar_frontend;
GRANT USAGE, SELECT ON ratings_id_seq TO edgar_frontend;




-- ////////////////////////////////////////////////////////////////////////////////////////////////////
-- CUSTOM FUNCTIONS
-- ////////////////////////////////////////////////////////////////////////////////////////////////////


-- Recalculates the "rating" (a.k.a vetting) on each occurrence
-- Uses a painters algorithm. Orders all ratings from least authoritative to
-- most authoritative, then applies the ratings to the area. This means the
-- most authoritative rating gets applied last, and therefor has the final
-- say.
--
-- Calls ST_SimplifyPreserveTopology on the rating polygons, because they
-- can be super high resolution which makes ST_CoveredBy run super slow.
--
-- Run this with: SELECT EdgarUpdateRatings(x);
-- Where `x` is a valid species.id

DROP FUNCTION IF EXISTS EdgarUpdateRatings(species.id%TYPE);

CREATE FUNCTION EdgarUpdateRatings(speciesId species.id%TYPE) RETURNS varchar AS $$
DECLARE
    r RECORD;
BEGIN
    -- Revert back to original ratings, as obtained from the source
    UPDATE occurrences
        SET rating = source_rating
        WHERE species_id = speciesId;

    -- Apply user ratings using painters algorithm
    FOR r IN
        -- TODO: order this loop from least authoritative user to most authoritative.
        -- TODO: what if two ratings by the same user overlap? What takes precedence?
        SELECT *
            FROM ratings
                JOIN users on ratings.user_id = users.id
            WHERE ratings.species_id = speciesId
                AND users.can_rate
    LOOP
        UPDATE occurrences
            SET rating = r.rating
            WHERE occurrences.species_id = speciesId
                AND ST_CoveredBy(occurrences.location, ST_SimplifyPreserveTopology(r.area, 0.01));
    END LOOP;

    RETURN 'DONE';
END;
$$ LANGUAGE plpgsql;
