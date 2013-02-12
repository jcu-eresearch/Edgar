# == Schema Information
#
# Table name: occurrences
#
#  id                    :integer          not null, primary key
#  uncertainty           :integer
#  date                  :date
#  classification        :classification   not null
#  basis                 :occurrence_basis
#  contentious           :boolean          default(FALSE), not null
#  source_classification :classification
#  source_record_id      :binary
#  species_id            :integer          not null
#  source_id             :integer          not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  location              :spatial({:srid=>
#

class Occurrence < ActiveRecord::Base

  # The smallest grid size for which clustering is enabled.
  # Below this value, grid size is set to nil (no clustering).

  MIN_GRID_SIZE_BEFORE_NO_CLUSTERING = 0.015

  # The grid size is the span of window divided by GRID_SIZE_WINDOW_FRACTION

  GRID_SIZE_WINDOW_FRACTION = 10

  # Develop the buffered_cluster_envelope by increasing buffering the cluster's
  # centroid by grid_size/CLUSTER_GRID_SIZE_BUFFER_FRACTION.

  CLUSTER_GRID_SIZE_BUFFER_FRACTION = 4

  # The SRID (projection format) this model uses

  SRID = 4326

  attr_readonly :basis, :classification, :contentious, :date, :location, :occurrence_basis, :source_classification, :source_id, :source_record_id, :species_id, :uncertainty

  belongs_to :species
  belongs_to :source

  before_destroy :prevent_destroy

  self.rgeo_factory_generator = RGeo::Geos.factory_generator
  set_rgeo_factory_for_column(:location, RGeo::Geographic.spherical_factory(srid: SRID))

  # Get the occurrences that fall inside the bbox
  # [+bbox] an Array of floats (lat/lng degrees decimal) [w, s, e, n]

  def self.in_rect(bbox)
    w, s, e, n = *bbox.map { |v| v.to_f }

    where("location && ST_MakeEnvelope(?, ?, ?, ?, ?)", w, s, e, n, SRID)
  end

  # Given a bbox, determine the appropriate grid size
  # for clustering.
  # If bbox is nil, returns a grid_size of nil.
  #
  # [+:bbox+]      a String representing a bbox "#{w}, #{s}, #{e}, #{n}".

  def self.get_cluster_grid_size(bbox=nil)
    return nil if bbox.nil?
    bbox = bbox.split(',').map { |el| el.to_f }
    w, s, e, n = *bbox

    lat_range = w - e
    lng_range = n - s

    lat_lng_range_avg = (lat_range + lng_range) / 2
    lat_lng_range_avg = lat_lng_range_avg.abs

    grid_size = ( lat_lng_range_avg / GRID_SIZE_WINDOW_FRACTION.to_f ).round(3)
    grid_size = nil if grid_size < MIN_GRID_SIZE_BEFORE_NO_CLUSTERING

    grid_size
  end

  def self.select_classification_totals
    qry = self

    Classification::ALL_CLASSIFICATIONS.each do |classification|
      qry = qry.
        select(sanitize_sql_array(
          ["sum(case when classification = '%s' then 1 else 0 end) as %s", classification, "#{classification}_count"]
        )).
        select(sanitize_sql_array(
          ["sum(case when classification = '%s' and contentious = true then 1 else 0 end) as %s", classification, "contentious_#{classification}_count"]
        ))
    end

    qry.select("sum(case when contentious = true then 1 else 0 end) as contentious_count")

  end

  # Where the classification of the occurrence isn't invalid.

  def self.where_not_invalid
    where('classification != ?', :invalid)
  end

  # Use the ST_SnapToGrid PostGIS function to cluster the occurrences.
  #
  # +options+ include:
  #
  # [+:grid_size+] a Float representing the size of the
  #                clusters (lat/lng degrees decimal)
  # [+:bbox+]      a String representing a bbox "#{w}, #{s}, #{e}, #{n}".
  #                Will be used to calculate a +grid_size+ if no +grid_size+
  #                option is provided.
  #
  # If grid_size is determined to be nil, clusters will simply be the result of a group by location.
  # i.e. Clusters of exact geometries (e.g. the same point)
  #
  # Returns an ActiveRecord::Relation which when executed will result in
  # rows. Each row will have the following instance variables:
  #
  # [+cluster_location_count+] the number of geometries in the cluster
  # [+cluster_centroid+] the middle point of the cluster
  #
  # The following is an example of the SQL that this will produce:
  #
  #   select
  #     count(location) as cluster_location_count,
  #     ST_AsText(ST_Centroid(ST_Collect( location ))) AS cluster_centroid
  #   from "occurrences"
  #   group by
  #     ST_SnapToGrid(location, :grid_size)
  #   ;

  def self.cluster options
    bbox      = options[:bbox]
    grid_size = options[:grid_size] || get_cluster_grid_size(bbox)

    qry = self

    qry = qry.select{count(location).as("cluster_location_count")}

    if grid_size.nil?
      qry = qry.
        select{st_astext(location).as("cluster_centroid")}.
        select{st_astext(st_envelope(st_collect(location))).as("cluster_envelope")}.
        select{
          st_astext(
            st_expand(st_envelope(location), MIN_GRID_SIZE_BEFORE_NO_CLUSTERING)
          ).as("buffered_cluster_envelope")
        }.
        group{location}
    else
      qry = qry.
        select{st_astext(st_centroid(st_collect(location))).as("cluster_centroid")}.
        select{st_astext(st_envelope(st_collect(location))).as("cluster_envelope")}.
        # explanation of this next select:
        # select the envelope (bbox) of the union of 2 things:
        # 1. the collection of locations that this cluster represents
        # 2. a geom that is the centroid of the cluster buffered in all directions by a third of
        #    the grid size.
        # The idea is, we always want the range of the cluster to at least represent
        # what is in it.
        # But in addition, we also want the vetting polygons created based on this
        # cluster to at least cover a reasonable area (and not be too small).
        select{
          st_astext(
            st_envelope(
              st_collect(
                st_buffer(st_centroid(st_collect(location)), grid_size/CLUSTER_GRID_SIZE_BUFFER_FRACTION),
                st_envelope(st_collect(location))
              )
            )
          ).as("buffered_cluster_envelope")
        }.
        group{st_snaptogrid(location, grid_size)}
    end

    return qry
  end

  private

  def prevent_destroy
    errors.add(:base, "Can't destroy an occurrence")
    false
  end
end
