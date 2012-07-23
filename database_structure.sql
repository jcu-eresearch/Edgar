-- SQL compatible with PostgreSQL v8.4 + PostGIS 1.5

DROP FUNCTION IF EXISTS EdgarUpsertOccurrence(classification, DATE, INT, FLOAT, FLOAT, FLOAT, FLOAT, INT, INT, INT, bytea);
DROP TABLE IF EXISTS sensitive_occurrences;
DROP TABLE IF EXISTS occurrences;
DROP TABLE IF EXISTS sources;
DROP TABLE IF EXISTS vettings;
DROP TABLE IF EXISTS species;
DROP TABLE IF EXISTS users;
DROP TYPE IF EXISTS classification;



-- ////////////////////////////////////////////////////////////////////////////////////////////////////
-- CUSTOM TYPES
-- ////////////////////////////////////////////////////////////////////////////////////////////////////

-- The classification enum has these values, in order:
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
-- The occurrence should be used in modelling if the vetting's classification is "irruptive" or better.

CREATE TYPE classification AS ENUM(
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
    needs_vetting_since TIMESTAMP DEFAULT NULL NULL, -- When this species began needing a re-vet. Null means the species does not need to be re-vetted.
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
    last_successfully_completed_model_importance SMALLINT DEFAULT NULL NULL, -- The importance the species had when the last successfully completed model was queued
    last_applied_vettings TIMESTAMP DEFAULT NULL NULL    -- When were the classifications of occurrences for this species last calc'd based on vettings
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
    uncertainty INT NOT NULL, -- uncertainty of location in meters. Not sure if this is a radius, or width of a square bounding box. Bounding box makes sense, if the lat/lon are rounded.
    date DATE NULL, -- when the occurrence/sighting happened
    classification classification NOT NULL, -- The canonical classification (a.k.a "vetting") for the occurrence
    contentious BOOL DEFAULT FALSE NOT NULL,
    source_classification classification NOT NULL, -- The vetting classification as obtained from the source (i.e. ALA assertions translated to our vettings system)
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
-- Reduces disk access for queries with `where species_id = ?` (which is like 100% of queries)
-- Do this manually, can take hours and a double the disk space of the table:
-- CLUSTER occurrences USING occurrences_species_id_idx;
-- VACUUM ANALYSE occurrences;


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
    email VARCHAR(256) NULL, -- NULL indicates that this user doesn't come from ALA (e.g. birdlife australia vettings)
    fname VARCHAR(256) NOT NULL,
    lname VARCHAR(256) NOT NULL,
    can_vet BOOLEAN DEFAULT TRUE NOT NULL,
    is_admin BOOLEAN DEFAULT FALSE NOT NULL,
    authority INT DEFAULT 1000 NOT NULL
);


-- These are the user vettings (a.k.a vetting information) for
-- occurrences. Each row is arbitrary area to which a specific classification enum
-- value applies, by a single user for a single species. ALA has a system of
-- "assertions" that doesn't match up very will to the way we will be vetting 
-- occurrences.
CREATE TABLE vettings (
    id SERIAL NOT NULL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    species_id INT NOT NULL REFERENCES species(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    comment TEXT NOT NULL, -- additional free-form comment supplied by the user
    classification classification NOT NULL,

    created          TIMESTAMP NOT NULL DEFAULT now(),     -- The time the vetting was created
    modified         TIMESTAMP NOT NULL DEFAULT now(),     -- The time the vetting was modified
    deleted          TIMESTAMP DEFAULT NULL NULL,          -- The time the vetting was deleted (NULL if not deleted)
    last_ala_sync    TIMESTAMP DEFAULT NULL NULL           -- The time the vetting was last synced with ALA (NULL if never sync'd)
);
SELECT AddGeometryColumn('vettings', 'area', 4326, 'MULTIPOLYGON', 2);
ALTER TABLE vettings ALTER COLUMN area SET NOT NULL;
ALTER TABLE vettings ADD CONSTRAINT vettings_area_valid_check CHECK (ST_IsValid(area));




-- ////////////////////////////////////////////////////////////////////////////////////////////////////
-- PERMISSIONS
-- ////////////////////////////////////////////////////////////////////////////////////////////////////
-- Assumes that there are two users/roles: edgar_frontend and edgar_backend.
-- Also assumes this SQL is running with grant privileges

-- edgar_backend
GRANT ALL ON species TO edgar_backend;
GRANT ALL ON sources TO edgar_backend;
GRANT ALL ON occurrences TO edgar_backend;
GRANT ALL ON sensitive_occurrences TO edgar_backend;
GRANT ALL ON vettings TO edgar_backend;
GRANT ALL ON users TO edgar_backend;
GRANT USAGE, SELECT ON species_id_seq TO edgar_backend;
GRANT USAGE, SELECT ON sources_id_seq TO edgar_backend;
GRANT USAGE, SELECT ON occurrences_id_seq TO edgar_backend;
GRANT USAGE, SELECT ON vettings_id_seq TO edgar_backend;

-- edgar_frontend
GRANT SELECT, UPDATE ON species TO edgar_frontend;
GRANT SELECT, INSERT ON users TO edgar_frontend;
GRANT SELECT ON occurrences TO edgar_frontend;
GRANT SELECT, INSERT, UPDATE ON vettings TO edgar_frontend;
GRANT USAGE, SELECT ON vettings_id_seq TO edgar_frontend;
GRANT USAGE, SELECT ON users_id_seq TO edgar_frontend;




-- ////////////////////////////////////////////////////////////////////////////////////////////////////
-- CUSTOM FUNCTIONS
-- ////////////////////////////////////////////////////////////////////////////////////////////////////

-- Inserts/updates (upserts) an occurrence, and its related
-- sensitive_occurrence if necessary. This is a slow operation in python, and
-- is about twice as fast using a stored procedure.

CREATE FUNCTION EdgarUpsertOccurrence(
    inClassification classification,
    inDate DATE,
    inSRID INT,
    inLat FLOAT,
    inLon FLOAT,
    inSensLat FLOAT,
    inSensLon FLOAT,
    inUncertainty INT,
    inSpeciesId INT,
    inSourceId INT,
    inSourceRecordId bytea) RETURNS VOID AS $$
DECLARE
    inOccurrenceId INT;
BEGIN
    inOccurrenceId := NULL;

    -- try update first
    UPDATE occurrences
        SET
            location = ST_SetSRID(ST_Point(inLon, inLat), inSRID),
            species_id = inSpeciesId,
            source_classification = inClassification,
            date = inDate,
            uncertainty = inUncertainty
        WHERE
            source_id = inSourceId
            AND source_record_id = inSourceRecordId
        RETURNING id INTO inOccurrenceId;

    -- if nothing was updated, insert new row
    IF inOccurrenceId IS NULL THEN
        INSERT INTO occurrences (
                location,
                source_classification,
                classification,
                date,
                uncertainty,
                species_id,
                source_id,
                source_record_id
            ) VALUES (
                ST_SetSRID(ST_Point(inLon, inLat), inSRID),
                inClassification,
                inClassification,
                inDate,
                inUncertainty,
                inSpeciesId,
                inSourceId,
                inSourceRecordId
            ) RETURNING id INTO inOccurrenceId;
    END IF;

    -- stop if no sensitive coord
    IF inSensLat IS NULL OR inSensLon IS NULL THEN
        RETURN;
    END IF;

    -- try update sensitive coord
    UPDATE sensitive_occurrences
        SET sensitive_location = ST_SetSRID(ST_Point(inSensLon, inSensLat), inSRID)
        WHERE occurrence_id = inOccurrenceId;

    -- if nothing was updated, insert new row
    IF NOT FOUND THEN
        INSERT INTO sensitive_occurrences(occurrence_id, sensitive_location)
            VALUES(inOccurrenceId, ST_SetSRID(ST_Point(inSensLon, inSensLat), inSRID));
    END IF;
END;
$$ LANGUAGE plpgsql;

