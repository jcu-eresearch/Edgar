-- SQL compatible with PostgreSQL v8.4
--
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

-- Each species has many occurrences, and each occurrence belongs to one species.
CREATE TABLE species (
    id SERIAL NOT NULL PRIMARY KEY,
    scientific_name VARCHAR(256) NOT NULL, -- Format: Genus (subgenus) species
    common_name VARCHAR(256) NULL, -- Some species don't have a common name
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
-- so this table should have as few columns as possible.
--
-- Maybe add a "has_user_ratings" column as an optimisation, so that
-- you don't have to make a separate query to find out if the
-- occurrence has any user ratings.
--
-- TODO: find out how precise lat/longs need to be (float or double)
CREATE TABLE occurrences (
    id SERIAL NOT NULL PRIMARY KEY,
    latitude FLOAT NOT NULL,
    longitude FLOAT NOT NULL,
    rating rating NOT NULL,
    species_id INT NOT NULL, -- foreign key to species.id
    source_id INT NOT NULL, -- foreign key to sources.id
    source_record_id bytea NULL -- the id of the record as obtained from the source (e.g. the uuid from ALA)
);
CREATE INDEX occurrences_species_id_idx ON occurrences (species_id);
CREATE UNIQUE INDEX occurrences_source_record_idx ON occurrences (source_id, source_record_id);


CREATE TABLE users (
    id SERIAL NOT NULL PRIMARY KEY,
    email VARCHAR(256) NOT NULL,
    fname VARCHAR(256) NOT NULL,
    lname VARCHAR(256) NOT NULL,
    can_rate BOOLEAN DEFAULT TRUE NOT NULL,
    is_admin BOOLEAN DEFAULT FALSE NOT NULL
);


-- These are the user ratings (a.k.a vetting information) for
-- occurrence occurrences. ALA has a system of "assertions" that
-- doesn't match up very will to the way we will be rating
-- occurrences. Has a many-to-many relationship with the 'occurrences'
-- table via the 'occurrences_ratings_bridge' table.
CREATE TABLE ratings (
    id SERIAL NOT NULL PRIMARY KEY,
    user_id INT NOT NULL, -- foreign key into users.id
    comment TEXT NOT NULL, -- additional free-form comment supplied by the user
    rating rating NOT NULL
);
