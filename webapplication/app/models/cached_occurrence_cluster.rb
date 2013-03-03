class CachedOccurrenceCluster < ActiveRecord::Base

  attr_readonly :species_cache_record_id, :cluster_size, :cluster_centroid, :cluster_envelope, :buffered_cluster_envelope

  Classification::ALL_CLASSIFICATIONS.each do |classification|
    attr_readonly "#{classification}_count".to_sym
    attr_readonly "contentious_#{classification}_count".to_sym
  end

  # A species will have many species cache records

  belongs_to :species_cache_record

  SRID = 4326

  self.rgeo_factory_generator = RGeo::Geos.factory_generator

  set_rgeo_factory_for_column(:cluster_centroid, RGeo::Geographic.spherical_factory(srid: SRID))
  set_rgeo_factory_for_column(:cluster_envelope, RGeo::Geographic.spherical_factory(srid: SRID))
  set_rgeo_factory_for_column(:buffered_cluster_envelope, RGeo::Geographic.spherical_factory(srid: SRID))

  def self.in_rect(bbox)
    w, s, e, n = *bbox.map { |v| v.to_f }

    where("cluster_centroid && ST_MakeEnvelope(?, ?, ?, ?, ?)", w, s, e, n, SRID)
  end

end

