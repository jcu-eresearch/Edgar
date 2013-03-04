--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

SET search_path = public, pg_catalog;

--
-- Name: classification; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE classification AS ENUM (
    'unknown',
    'invalid',
    'historic',
    'vagrant',
    'irruptive',
    'core',
    'introduced'
);


--
-- Name: occurrence_basis; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE occurrence_basis AS ENUM (
    'Preserved specimen',
    'Human observation',
    'Machine observation'
);


--
-- Name: edgarupsertoccurrence(classification, date, integer, double precision, double precision, double precision, double precision, integer, occurrence_basis, integer, integer, bytea); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION edgarupsertoccurrence(inclassification classification, indate date, insrid integer, inlat double precision, inlon double precision, insenslat double precision, insenslon double precision, inuncertainty integer, inbasis occurrence_basis, inspeciesid integer, insourceid integer, insourcerecordid bytea) RETURNS void
    LANGUAGE plpgsql
    AS $$
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
                  uncertainty = inUncertainty,
                  basis = inBasis
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
                      basis,
                      species_id,
                      source_id,
                      source_record_id
                  ) VALUES (
                      ST_SetSRID(ST_Point(inLon, inLat), inSRID),
                      inClassification,
                      inClassification,
                      inDate,
                      inUncertainty,
                      inBasis,
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
      $$;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: cached_occurrence_clusters; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE cached_occurrence_clusters (
    id integer NOT NULL,
    species_cache_record_id integer NOT NULL,
    cluster_size integer NOT NULL,
    contentious_count integer NOT NULL,
    unknown_count integer,
    contentious_unknown_count integer,
    invalid_count integer,
    contentious_invalid_count integer,
    historic_count integer,
    contentious_historic_count integer,
    vagrant_count integer,
    contentious_vagrant_count integer,
    irruptive_count integer,
    contentious_irruptive_count integer,
    core_count integer,
    contentious_core_count integer,
    introduced_count integer,
    contentious_introduced_count integer,
    cluster_centroid geometry(Point,4326),
    cluster_envelope geometry(Geometry,4326),
    buffered_cluster_envelope geometry(Geometry,4326)
);


--
-- Name: cached_occurrence_clusters_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE cached_occurrence_clusters_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cached_occurrence_clusters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE cached_occurrence_clusters_id_seq OWNED BY cached_occurrence_clusters.id;


--
-- Name: occurrences; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE occurrences (
    id integer NOT NULL,
    uncertainty integer,
    date date,
    classification classification NOT NULL,
    basis occurrence_basis,
    contentious boolean DEFAULT false NOT NULL,
    source_classification classification,
    source_record_id bytea,
    species_id integer NOT NULL,
    source_id integer NOT NULL,
    location geometry(Point,4326)
);


--
-- Name: occurrences_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE occurrences_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: occurrences_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE occurrences_id_seq OWNED BY occurrences.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: sensitive_occurrences; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE sensitive_occurrences (
    id integer NOT NULL,
    occurrence_id integer NOT NULL,
    sensitive_location geometry(Point,4326)
);


--
-- Name: sensitive_occurrences_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sensitive_occurrences_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sensitive_occurrences_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sensitive_occurrences_id_seq OWNED BY sensitive_occurrences.id;


--
-- Name: sources; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE sources (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    url character varying(255) DEFAULT ''::character varying NOT NULL,
    last_import_time timestamp without time zone
);


--
-- Name: sources_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sources_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sources_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sources_id_seq OWNED BY sources.id;


--
-- Name: species; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE species (
    id integer NOT NULL,
    scientific_name character varying(255) NOT NULL,
    common_name character varying(255),
    num_dirty_occurrences integer DEFAULT 0 NOT NULL,
    num_contentious_occurrences integer DEFAULT 0 NOT NULL,
    needs_vetting_since timestamp without time zone,
    has_occurrences boolean DEFAULT false NOT NULL,
    first_requested_remodel timestamp without time zone,
    current_model_status character varying(255),
    current_model_queued_time timestamp without time zone,
    current_model_importance integer,
    last_completed_model_queued_time timestamp without time zone,
    last_completed_model_finish_time timestamp without time zone,
    last_completed_model_importance integer,
    last_completed_model_status character varying(255),
    last_completed_model_status_reason character varying(255),
    last_successfully_completed_model_queued_time timestamp without time zone,
    last_successfully_completed_model_finish_time timestamp without time zone,
    last_successfully_completed_model_importance integer,
    last_applied_vettings timestamp without time zone
);


--
-- Name: species_cache_records; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE species_cache_records (
    id integer NOT NULL,
    species_id integer NOT NULL,
    grid_size double precision,
    cache_generated_at timestamp without time zone NOT NULL,
    out_of_date_since timestamp without time zone
);


--
-- Name: species_cache_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE species_cache_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: species_cache_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE species_cache_records_id_seq OWNED BY species_cache_records.id;


--
-- Name: species_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE species_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: species_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE species_id_seq OWNED BY species.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users (
    id integer NOT NULL,
    email character varying(255),
    fname character varying(255) NOT NULL,
    lname character varying(255) NOT NULL,
    can_vet boolean DEFAULT true NOT NULL,
    is_admin boolean DEFAULT false NOT NULL,
    authority integer DEFAULT 1000 NOT NULL,
    username character varying(255) NOT NULL
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: vettings; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE vettings (
    id integer NOT NULL,
    user_id integer NOT NULL,
    species_id integer NOT NULL,
    comment text NOT NULL,
    classification classification NOT NULL,
    created timestamp without time zone DEFAULT now() NOT NULL,
    modified timestamp without time zone DEFAULT now() NOT NULL,
    deleted timestamp without time zone,
    ignored timestamp without time zone,
    last_ala_sync timestamp without time zone,
    area geometry(MultiPolygon,4326)
);


--
-- Name: vettings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE vettings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: vettings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE vettings_id_seq OWNED BY vettings.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY cached_occurrence_clusters ALTER COLUMN id SET DEFAULT nextval('cached_occurrence_clusters_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY occurrences ALTER COLUMN id SET DEFAULT nextval('occurrences_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY sensitive_occurrences ALTER COLUMN id SET DEFAULT nextval('sensitive_occurrences_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY sources ALTER COLUMN id SET DEFAULT nextval('sources_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY species ALTER COLUMN id SET DEFAULT nextval('species_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY species_cache_records ALTER COLUMN id SET DEFAULT nextval('species_cache_records_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY vettings ALTER COLUMN id SET DEFAULT nextval('vettings_id_seq'::regclass);


--
-- Name: cached_occurrence_clusters_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cached_occurrence_clusters
    ADD CONSTRAINT cached_occurrence_clusters_pkey PRIMARY KEY (id);


--
-- Name: occurrences_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY occurrences
    ADD CONSTRAINT occurrences_pkey PRIMARY KEY (id);


--
-- Name: sensitive_occurrences_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sensitive_occurrences
    ADD CONSTRAINT sensitive_occurrences_pkey PRIMARY KEY (id);


--
-- Name: sources_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sources
    ADD CONSTRAINT sources_pkey PRIMARY KEY (id);


--
-- Name: species_cache_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY species_cache_records
    ADD CONSTRAINT species_cache_records_pkey PRIMARY KEY (id);


--
-- Name: species_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY species
    ADD CONSTRAINT species_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: vettings_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY vettings
    ADD CONSTRAINT vettings_pkey PRIMARY KEY (id);


--
-- Name: index_cached_occurrence_clusters_on_cluster_centroid; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_cached_occurrence_clusters_on_cluster_centroid ON cached_occurrence_clusters USING btree (cluster_centroid);


--
-- Name: index_cached_occurrence_clusters_on_species_cache_record_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_cached_occurrence_clusters_on_species_cache_record_id ON cached_occurrence_clusters USING btree (species_cache_record_id);


--
-- Name: index_occurrences_on_location; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_occurrences_on_location ON occurrences USING gist (location);


--
-- Name: index_occurrences_on_species_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_occurrences_on_species_id ON occurrences USING btree (species_id);


--
-- Name: index_sensitive_occurrences_on_occurrence_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_sensitive_occurrences_on_occurrence_id ON sensitive_occurrences USING btree (occurrence_id);


--
-- Name: index_sensitive_occurrences_on_sensitive_location; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_sensitive_occurrences_on_sensitive_location ON sensitive_occurrences USING gist (sensitive_location);


--
-- Name: index_species_cache_records_on_grid_size; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_species_cache_records_on_grid_size ON species_cache_records USING btree (grid_size);


--
-- Name: index_species_cache_records_on_out_of_date_since; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_species_cache_records_on_out_of_date_since ON species_cache_records USING btree (out_of_date_since);


--
-- Name: index_species_cache_records_on_species_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_species_cache_records_on_species_id ON species_cache_records USING btree (species_id);


--
-- Name: index_users_on_username; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_username ON users USING btree (username);


--
-- Name: index_vettings_on_area; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_vettings_on_area ON vettings USING gist (area);


--
-- Name: index_vettings_on_species_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_vettings_on_species_id ON vettings USING btree (species_id);


--
-- Name: index_vettings_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_vettings_on_user_id ON vettings USING btree (user_id);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- Name: geometry_columns_delete; Type: RULE; Schema: public; Owner: -
--

CREATE RULE geometry_columns_delete AS ON DELETE TO geometry_columns DO INSTEAD NOTHING;


--
-- Name: geometry_columns_insert; Type: RULE; Schema: public; Owner: -
--

CREATE RULE geometry_columns_insert AS ON INSERT TO geometry_columns DO INSTEAD NOTHING;


--
-- Name: geometry_columns_update; Type: RULE; Schema: public; Owner: -
--

CREATE RULE geometry_columns_update AS ON UPDATE TO geometry_columns DO INSTEAD NOTHING;


--
-- PostgreSQL database dump complete
--

