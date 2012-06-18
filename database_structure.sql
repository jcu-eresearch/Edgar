-- SQL compatible with PostgreSQL v8.4 + PostGIS 1.5

DROP FUNCTION IF EXISTS EdgarUpdateRatings(species.id%TYPE);
DROP TABLE IF EXISTS sensitive_occurrences;
DROP TABLE IF EXISTS occurrences;
DROP TABLE IF EXISTS sources;
DROP TABLE IF EXISTS ratings;
DROP TABLE IF EXISTS species;
DROP TABLE IF EXISTS users;
DROP TYPE IF EXISTS rating;



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
    scientific_name VARCHAR(256) NOT NULL, -- Format: "Genus (subgenus) species" where "(subgenus)" is optional
    common_name VARCHAR(256) NULL, -- Some species don't have a common name (can be null)
    num_dirty_occurrences INT DEFAULT 0 NOT NULL, -- This is the number of occurrences that have changed since the last modelling run happened
    -- Modelling status (current)
    first_requested_remodel TIMESTAMP DEFAULT NULL NULL, -- The first time, since last modelling run, that a user requested a remodel for this species
    -- Modelling current
    current_model_status VARCHAR(256) DEFAULT NULL NULL, -- NULL if no modeling run is happening for this species, otherwise a message indicating the status of the modeling run
    current_model_queued_time TIMESTAMP DEFAULT NULL NULL, -- NULL if no modelling run is happening for this species, otherwise time the model was queued on the HPC
    current_model_importance SMALLINT DEFAULT NULL NULL, -- NULL if no modelling run is happening for this species, otherwise an integer representing the importance (priority) of the model
    -- Modelling most recently completed
    last_completed_model_queued_time TIMESTAMP DEFAULT NULL NULL, -- The time that the last completed model was queued
    last_completed_model_finish_time TIMESTAMP DEFAULT NULL NULL, -- The time that the last completed model finished
    last_completed_model_importance SMALLINT DEFAULT NULL NULL, -- The importance the species had when the last completed model was queued
    last_completed_model_status VARCHAR(256) DEFAULT NULL NULL, -- The status of the model when it completed. Should be FINISHED_SUCCESS or FINISHED_FAILURE
    last_completed_model_status_reason VARCHAR(256) DEFAULT NULL NULL, -- The reason for the status of the model when it completed
    -- Modelling most recently successfully completed
    last_successfully_completed_model_queued_time TIMESTAMP DEFAULT NULL NULL, -- The importance the species had when the last successfully completed model was queued
    last_successfully_completed_model_finish_time TIMESTAMP DEFAULT NULL NULL, -- The importance the species had when the last successfully completed model was queued
    last_successfully_completed_model_importance SMALLINT DEFAULT NULL NULL -- The importance the species had when the last successfully completed model was queued
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
    source_rating rating NOT NULL, -- The rating as obtained from the source (i.e. ALA assertions translated to our ratings system)
    source_record_id bytea NULL, -- the id of the record as obtained from the source (e.g. the uuid from ALA)
    species_id INT NOT NULL REFERENCES species(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    source_id INT NOT NULL REFERENCES sources(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);
SELECT AddGeometryColumn('occurrences', 'location', 4326, 'POINT', 2);
ALTER TABLE occurrences ALTER COLUMN location SET NOT NULL;
CREATE INDEX occurrences_species_id_idx ON occurrences (species_id);
CREATE UNIQUE INDEX occurrences_source_record_idx ON occurrences (source_id, source_record_id);
CREATE INDEX occurrences_location_idx ON occurrences USING GIST (location);
-- Do this manually, can take hours:
-- CLUSTER occurrences USING occurrences_location_idx;
VACUUM ANALYSE occurrences;


-- SHOULD NOT BE ACCESSABLE TO THE PUBLIC.
-- Join this table to the occurrences table for access to the sensitive_location
CREATE TABLE sensitive_occurrences (
    occurrence_id INT NOT NULL REFERENCES occurrences(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
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
    user_id INT NOT NULL REFERENCES users(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    species_id INT NOT NULL REFERENCES species(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
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
