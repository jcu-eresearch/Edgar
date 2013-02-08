# == Schema Information
#
# Table name: species
#
#  id                                            :integer          not null, primary key
#  scientific_name                               :string(255)      not null
#  common_name                                   :string(255)
#  num_dirty_occurrences                         :integer          default(0), not null
#  num_contentious_occurrences                   :integer          default(0), not null
#  needs_vetting_since                           :datetime
#  has_occurrences                               :boolean          default(FALSE), not null
#  first_requested_remodel                       :datetime
#  current_model_status                          :string(255)
#  current_model_queued_time                     :datetime
#  current_model_importance                      :integer
#  last_completed_model_queued_time              :datetime
#  last_completed_model_finish_time              :datetime
#  last_completed_model_importance               :integer
#  last_completed_model_status                   :string(255)
#  last_completed_model_status_reason            :string(255)
#  last_successfully_completed_model_queued_time :datetime
#  last_successfully_completed_model_finish_time :datetime
#  last_successfully_completed_model_importance  :integer
#  last_applied_vettings                         :datetime
#  created_at                                    :datetime         not null
#  updated_at                                    :datetime         not null
#

class Species < ActiveRecord::Base

  # The maximum number of features to return from a query
  FEATURES_QUERY_LIMIT = 1000
  SEARCH_QUERY_LIMIT = 100
  MIN_FEATURE_RADIUS = 3

  # These attributes are readonly
  attr_readonly :common_name, :scientific_name, :last_applied_vettings, :needs_vetting_since
  # All other attributes will default to attr_protected (non mass assignable)

  has_many :occurrences
  has_many :vettings

  before_destroy :check_for_occurrences_or_vettings

  # A case insensitive search of species.
  #
  # [+term+] the search term can exist at any position in either the common_name or the scientific_name.
  # [+order_by+] is what the search result will be ordered by (default +:common_name+).

  def self.search_by_common_name_or_scientific_name term, order_by=:common_name
    Species.
      order(order_by).
      where("common_name ILIKE ? or scientific_name ILIKE ?", "%#{term}%", "%#{term}%").
      limit(SEARCH_QUERY_LIMIT)
  end

  # Returns an array of GeoJSON::Feature for this species.
  # Uses +options+ to define how to build a custom array of features.
  # +options+ include:
  #
  # [+:bbox+] a String representing a bbox "#{w}, #{s}, #{e}, #{n}"
  # [+:cluster+] +!nil+ if you want the features to be clustered
  # [+:grid_size+] a Float representing the size of the clusters (lat/lng degrees decimal)
  #
  # The size of the array returned is limited by +FEATURES_QUERY_LIMIT+
  # regardless of options
  #
  # Note: The GeoJSON::Feature object type is used as a convenience wrapper to
  # allow the location to be provided with additional information (properties and feature_id).
  # The underlying location can be attained via the GeoJSON::Feature instance
  # function location().
  #
  # *Important*: The GeoJSON::Feature is a wrapper. It isn't the same as RGeo::Feature::Geometry.
  # You should _peel back_ the wrapper if you intend to use the feature for anything
  # other than GeoJSON encoding. You can _peel back_ the wrapper via the GeoJSON::Feature
  # instance function +location()+.

  def get_features(options)
    features = []
    occurrences_relation = nil
    if options[:bbox]
      occurrences_relation = occurrences.in_rect(options[:bbox].split(','))
    else
      occurrences_relation = occurrences
    end

    if options[:cluster]
      cluster_result = nil
      cluster_result = occurrences_relation.cluster(options)
      cluster_result.limit(FEATURES_QUERY_LIMIT).each do |cluster|
        geom_feature = Occurrence.rgeo_factory_for_column(:location).parse_wkt(cluster.cluster_centroid)

        feature = RGeo::GeoJSON::Feature.new(geom_feature, nil, get_feature_properties(cluster, geom_feature, options))

        features << feature
      end
    else
      occurrences_relation.limit(FEATURES_QUERY_LIMIT).each do |occurrence|
        geom_feature = occurrence.location
        feature = RGeo::GeoJSON::Feature.new(geom_feature, occurrence.id, get_feature_properties(occurrence, geom_feature, options))
        features << feature
      end
    end

    features
  end

  # Returns the species' +occurrences+ as a GeometryCollection
  # in *GeoJSON* (+String+)

  def get_geo_json(options={})
    features = get_features(options)
    feature_collection = RGeo::GeoJSON::FeatureCollection.new(features)
    RGeo::GeoJSON.encode(feature_collection)
  end

  # Returns the species' +occurrences+ as a GeometryCollection in *WKT* (+String+)

  def get_wkt(options={})
    features = get_features(options)
    geoms = features.map { |feature| feature.location() }
    feature_collection = Occurrence.rgeo_factory_for_column(:location).collection(geoms)
    feature_collection.as_text
  end

  # Merge the original Cake Attributes into the Rails attributes.
  # This provides backwards compatibility with existing Cake PHP javascript files.

  def serializable_hash(*args) 
    attrs = super(*args)
    attrs.merge({
      scientificName: scientific_name,
      commonName: common_name,
      numDirtyOccurrences: num_dirty_occurrences,
      canRequestRemodel: ( num_dirty_occurrences > 0 and first_requested_remodel.nil? ),
      remodelStatus: remodel_status_message,
      hasDownloadables: ( not last_successfully_completed_model_finish_time.nil? ),
      label: "#{common_name} - #{scientific_name}"
    })
  end

  # Get the next_job to model

  def self.next_job
    Species.
      select('*, first_requested_remodel IS NULL as is_null').
      order("is_null ASC, first_requested_remodel ASC, num_dirty_occurrences DESC").
      where(
        "num_dirty_occurrences > 0 AND current_model_status IS NULL " +
        "OR num_dirty_occurrences > 0 AND current_model_queued_time < ? " +
        "OR current_model_status <> NULL AND current_model_queued_time IS NULL",
        1.day.ago
      ).first
  end

  private

  # Returns a Hash of properties that descrive the cluster.
  # The cluster argument can be either a cluster, as returned by 
  # #Occurrence::cluster or a single #Occurrence.
  #
  # Note
  # -----
  #
  # This method is leaking View code into the Model.
  # The point radius logic should be in the javascript.

  def get_feature_properties cluster, geom_feature, options
    bbox = options[:bbox]

    # When looking at vetting,
    # create a box around the 
    grid_size = Occurrence::get_cluster_grid_size(bbox) || Occurrence::MIN_GRID_SIZE_BEFORE_NO_CLUSTERING

    common = {
      description: "",
      occurrence_type: "dotgrid",
      minlon: geom_feature.x - grid_size,
      maxlon: geom_feature.x + grid_size,
      minlat: geom_feature.y - grid_size,
      maxlat: geom_feature.y + grid_size,
    }

    if cluster.attributes.has_key? "cluster_location_count"
      common.merge({
        point_radius: Math::log2(cluster.cluster_location_count.to_i).floor + MIN_FEATURE_RADIUS,
        cluster_size: cluster.cluster_location_count.to_i,
        title: "#{cluster.cluster_location_count} points here",
        gridBounds: {
          minlon: geom_feature.x - grid_size,
          maxlon: geom_feature.x + grid_size,
          minlat: geom_feature.y - grid_size,
          maxlat: geom_feature.y + grid_size,
        }
      })
    else
      common.merge({
        point_radius: MIN_FEATURE_RADIUS,
        cluster_size: 1,
        title: "1 point here",
        occurrenceCoord: { lat: geom_feature.y, lon: geom_feature.x },
      })
    end
  end

  # Acts as a validation callback.
  #
  # Returns +false+ and adds an appropriate error to base
  # if the species has any occurrences.

  def check_for_occurrences_or_vettings
    if occurrences.count > 0 or vettings.count > 0
      errors.add(:base, "Can't destroy a species with occurrences or vettings")
      false
    end
  end

  # A human readable string representing the modelling status of this species.

  def remodel_status_message
    if num_dirty_occurrences <= 0
      "Up to date"
    elsif not current_model_status.nil?
      "Remodelling running with status: #{current_model_status}"
    elsif not first_requested_remodel.nil?
      "Priority queued for remodelling"
    else
      "Automatically queued for remodelling"
    end
  end
end
