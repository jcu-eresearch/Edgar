class CachedOccurrenceCluster < ActiveRecord::Base

  attr_readonly :species_cache_record_id, :cluster_size, :cluster_centroid, :cluster_envelope, :buffered_cluster_envelope

  Classification::ALL_CLASSIFICATIONS.each do |classification|
    attr_readonly "#{classification}_count".to_sym
    attr_readonly "contentious_#{classification}_count".to_sym
  end

  # A species will have many species cache records

  belongs_to :species_cache_record

end

