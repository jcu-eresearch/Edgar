class CreateGridClusteredOccurrencesCache < ActiveRecord::Migration
  def change
    create_table :species_cache_records do |t|
      # The cluster is for a specific species
      t.integer :species_id, null: false

      # The clusters were generated based on a grid_size of
      t.float :grid_size

      # When was the cache generated
      t.timestamp :cache_generated_at, null: false

      # If this isn't null, then the cache is out of date
      t.timestamp :out_of_date_since
    end

    change_table :species_cache_records do |t|
      t.index :species_id
      t.index :grid_size
      t.index :out_of_date_since
    end

    create_table :cached_occurrence_clusters do |t|
      # The cache record that this cluster is associated with
      t.integer :species_cache_record_id, null: false

      t.integer :cluster_size, null: false

      # Cluster Geoms
      t.point   :cluster_centroid, srid: 4326
      t.geometry :cluster_envelope, srid: 4326
      t.geometry :buffered_cluster_envelope, srid: 4326

      t.integer :contentious_count, null: false

      Classification::ALL_CLASSIFICATIONS.each do |classification|
        t.integer "#{classification}_count".to_sym
        t.integer "contentious_#{classification}_count".to_sym
      end

    end

    change_table :cached_occurrence_clusters do |t|
      t.index :species_cache_record_id
      t.index :cluster_centroid
    end

  end
end
