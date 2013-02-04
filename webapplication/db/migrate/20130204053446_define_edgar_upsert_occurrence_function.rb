class DefineEdgarUpsertOccurrenceFunction < ActiveRecord::Migration
  def up
    execute <<-SQL
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
          inBasis occurrence_basis,
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
      $$ LANGUAGE plpgsql;
    SQL
  end

  def down
    execute <<-SQL
      DROP FUNCTION IF EXISTS EdgarUpsertOccurrence(classification, DATE, INT, FLOAT, FLOAT, FLOAT, FLOAT, occurrence_basis, INT, INT, INT, bytea);
    SQL
  end
end
