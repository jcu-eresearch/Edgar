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

  FEATURES_QUERY_LIMIT = 5000

  # The max number of results to return from an autocomplete search

  SEARCH_QUERY_LIMIT = 20

  # The minimum radius a point feature should have

  MIN_FEATURE_RADIUS = 3

  # Cache the species occurrence clusters if we have more than
  # CACHE_OCCURRENCE_CLUSTERS_THRESHOLD occurrences for the species

  CACHE_OCCURRENCE_CLUSTERS_THRESHOLD = 10000

  # The list of actionable statuses a job can have.
  # A job can have other statuses, but they aren't acted upon.

  JOB_STATUS_LIST = {
    queued:                   "QUEUED",
    finished_successfully:    "FINISHED_SUCCESS",
    finished_due_to_failure:  "FINISHED_FAILURE"
  }

  # The importance a job can have

  JOB_IMPORTANCE = {
    background:     0,
    normal:         1,
    user_initiated: 2,
    urgent:         3
  }

  # These attributes are readonly
  attr_readonly :common_name, :scientific_name, :last_applied_vettings, :needs_vetting_since
  # All other attributes will default to attr_protected (non mass assignable)

  has_many :occurrences
  has_many :vettings
  has_many :species_cache_records, dependent: :destroy

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

  def self.has_occurrences
    where("has_occurrences")
  end

  def add_vetting!(user, vetting_classification, comment, area_wkt)
    now = Time.now

    vetting = vettings.new()

    vetting.classification = vetting_classification
    vetting.user = user
    vetting.comment = comment
    vetting.area = Vetting.select_simplified_area(area_wkt)
    vetting.created =  now
    vetting.modified = now

    vetting.save()
  end

  # Update's the status of a job
  #
  # [new_job_status] is the new job status
  # [new_job_status_message] is a human readable description of the job status,
  #                          useful to explain why something has gone wrong.
  # [dirty_occurrences] is the number of dirty_occurrences that existed when
  #                     the current job was started

  def update_job_status!(new_job_status, new_job_status_message=nil, dirty_occurrences=nil)
    new_job_status_message ||= ""
    dirty_occurrences = dirty_occurrences.to_i

    if current_model_status != new_job_status
      if new_job_status == Species::JOB_STATUS_LIST[:queued]
        # Update current model info for species
        self.current_model_status = new_job_status

        # Record when the job started
        self.current_model_queued_time = Time.now

        if first_requested_remodel.nil?
          self.current_model_importance = Species::JOB_IMPORTANCE[:normal]
        else
          self.current_model_importance = Species::JOB_IMPORTANCE[:user_initiated]
        end

      elsif (
          new_job_status == Species::JOB_STATUS_LIST[:finished_successfully] or
          new_job_status == Species::JOB_STATUS_LIST[:finished_due_to_failure]
        )

        self.last_completed_model_queued_time   = self.current_model_queued_time
        self.last_completed_model_finish_time   = Time.now()
        self.last_completed_model_importance    = self.current_model_importance
        self.last_completed_model_status        = new_job_status
        self.last_completed_model_status_reason = new_job_status_message

        if new_job_status == Species::JOB_STATUS_LIST[:finished_successfully]
          self.last_successfully_completed_model_queued_time = self.last_completed_model_queued_time
          self.last_successfully_completed_model_finish_time = self.last_completed_model_finish_time
          self.last_successfully_completed_model_importance  = self.last_completed_model_importance

          # If we cleared all the dirty occurrences
          if self.num_dirty_occurrences == dirty_occurrences
            self.num_dirty_occurrences = 0
          end
        end

        self.current_model_status       =  nil
        self.current_model_importance   =  nil
        self.current_model_queued_time  =  nil
        self.first_requested_remodel    =  nil

      else
        # A non-actionable status. Assume the job is running fine,
        # and store the job status
        self.current_model_status = new_job_status
      end

      save()
    end

    self
  end

  # Returns an array of GeoJSON::Feature for this species' occurrences.
  # Uses +options+ to define how to build a custom array of features.
  # +options+ include:
  #
  # [+:bbox+] a String representing a bbox "#{w}, #{s}, #{e}, #{n}"
  # [+:cluster+] +!nil+ if you want the features to be clustered
  # [+:grid_size+] a Float representing the size of the clusters (lat/lng degrees decimal)
  # [+:limit+] the max number of features to return. Can't exceed +FEATURES_QUERY_LIMIT+
  # [+:offset+] when used in conjunction with +:limit+ allows for pagination
  #
  # The size of the array returned is limited to +FEATURES_QUERY_LIMIT+
  # regardless of options
  #
  # Note: The GeoJSON::Feature object type is used as a convenience wrapper to
  # allow the location to be provided with additional information (properties and feature_id).
  # The underlying location can be attained via the GeoJSON::Feature instance
  # function geometry().
  #
  # *Important*: The GeoJSON::Feature is a wrapper. It isn't the same as RGeo::Feature::Geometry.
  # You should _peel back_ the wrapper if you intend to use the feature for anything
  # other than GeoJSON encoding. You can _peel back_ the wrapper via the GeoJSON::Feature
  # instance function +geometry()+.

  def get_occurrence_features(options)

    # Don't permit the user to exceed our max features query limit
    options[:limit] ||= FEATURES_QUERY_LIMIT
    options[:limit] = options[:limit].to_i
    options[:limit] = FEATURES_QUERY_LIMIT if options[:limit] > FEATURES_QUERY_LIMIT

    options[:offset] ||= 0
    options[:offset] = options[:offset].to_i

    features = []
    occurrences_relation = nil

    if options[:cluster] and options[:show_invalid]
      raise ArgumentError, "Invalid options (#{options.inspect}. The cluster interface uses caching, and we don't cache the invalid occurrence records"
    elsif options[:cluster]
      grid_size = options[:grid_size] || Occurrence::get_cluster_grid_size(options[:bbox])
      grid_size = Occurrence::normalise_grid_size(grid_size)

      cluster_result = get_or_generate_cached_clusters(grid_size)

      if options[:bbox]
        cluster_result = cluster_result.in_rect(options[:bbox].split(','))
      end

      cluster_result = cluster_result.limit(options[:limit])
      cluster_result = cluster_result.offset(options[:offset])

      cluster_result.each do |cluster|
        geom_feature = cluster.cluster_centroid
        feature = RGeo::GeoJSON::Feature.new(geom_feature, nil, get_occurrence_feature_properties(cluster, geom_feature, options))
        features << feature
      end
    else
      if options[:bbox]
        occurrences_relation = occurrences.in_rect(options[:bbox].split(','))
      else
        occurrences_relation = occurrences
      end

      unless options[:show_invalid]
        occurrences_relation = occurrences_relation.where_not_invalid
      end

      occurrences_relation = occurrences_relation.limit(options[:limit])
      occurrences_relation = occurrences_relation.offset(options[:offset])

      occurrences_relation.each do |occurrence|
        geom_feature = occurrence.location
        feature = RGeo::GeoJSON::Feature.new(geom_feature, occurrence.id, get_occurrence_feature_properties(occurrence, geom_feature, options))
        features << feature
      end
    end


    features
  end

  # Returns the species' +occurrences+ as a GeometryCollection
  # in *GeoJSON* (+String+)

  def get_occurrences_geo_json(options={})
    features = get_occurrence_features(options)
    feature_collection = RGeo::GeoJSON::FeatureCollection.new(features)
    RGeo::GeoJSON.encode(feature_collection)
  end

  # Returns the species' +occurrences+ as a GeometryCollection in *WKT* (+String+)

  def get_occurrences_wkt(options={})
    features = get_occurrence_features(options)
    geoms = features.map { |feature| feature.geometry() }
    feature_collection = Occurrence.rgeo_factory_for_column(:location).collection(geoms)
    feature_collection.as_text
  end

  # Returns an array of GeoJSON::Feature for this species' vettings.
  # Uses +options+ to define how to build a custom array of features.
  # +options+ include:
  #
  # [+:bbox+] a String representing a bbox "#{w}, #{s}, #{e}, #{n}"
  # [+:limit+] the max number of features to return. Can't exceed +FEATURES_QUERY_LIMIT+
  # [+:offset+] when used in conjunction with +:limit+ allows for pagination
  # [+:by_user_id+] show vettings made by this user.
  # [+:inverse_user_id_filter+] if set, then invert the by_user_id filter, i.e. show
  #                             vettings made by users other than the +:by_user_id user+.
  #
  # The size of the array returned is limited to +FEATURES_QUERY_LIMIT+
  # regardless of options
  #
  # Note: The GeoJSON::Feature object type is used as a convenience wrapper to
  # allow the vetting area to be provided with additional information (properties and feature_id).
  # The underlying area can be attained via the GeoJSON::Feature instance
  # function geometry().
  #
  # *Important*: The GeoJSON::Feature is a wrapper. It isn't the same as RGeo::Feature::Geometry.
  # You should _peel back_ the wrapper if you intend to use the feature for anything
  # other than GeoJSON encoding. You can _peel back_ the wrapper via the GeoJSON::Feature
  # instance function +geometry()+.

  def get_vetting_features(options)

    # Don't permit the user to exceed our max features query limit
    options[:limit] ||= FEATURES_QUERY_LIMIT
    options[:limit] = options[:limit].to_i
    options[:limit] = FEATURES_QUERY_LIMIT if options[:limit] > FEATURES_QUERY_LIMIT

    options[:offset] ||= 0
    options[:offset] = options[:offset].to_i

    features = []
    vettings_relation = nil

    if options[:bbox]
      vettings_relation = vettings.where_not_deleted.in_rect(options[:bbox].split(','))
    else
      vettings_relation = vettings.where_not_deleted
    end

    if filter_by_user_id = options[:by_user_id]
      if options[:inverse_user_id_filter]
        vettings_relation = vettings_relation.where_user_is_not(filter_by_user_id)
      else
        vettings_relation = vettings_relation.where_user_is(filter_by_user_id)
      end
    end

    vettings_relation = vettings_relation.limit(options[:limit])
    vettings_relation = vettings_relation.offset(options[:offset])

    vettings_relation.joins(:users)

    vettings_relation.each do |vetting|
      geom_feature = vetting.area
      feature = RGeo::GeoJSON::Feature.new(geom_feature, vetting.id, vetting.serializable_hash)
      features << feature
    end

    features
  end

  # Returns the species' +vettings+ as a GeometryCollection
  # in *GeoJSON* (+String+)

  def get_vettings_geo_json(options={})
    features = get_vetting_features(options)
    feature_collection = RGeo::GeoJSON::FeatureCollection.new(features)
    RGeo::GeoJSON.encode(feature_collection)
  end

  # Returns the species' +vettings+ as a GeometryCollection in *WKT* (+String+)

  def get_vettings_wkt(options={})
    features = get_vetting_features(options)
    geoms = features.map { |feature| feature.geometry() }
    feature_collection = Vetting.rgeo_factory_for_column(:area).collection(geoms)
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

  # Get the clusters at a fixes grid size.
  #
  # Use an existing in date cache if we have one,
  # else generate a cache.

  def get_or_generate_cached_clusters(grid_size)
    # Get a cache record that isn't nil
    cache_record = species_cache_records.find_by_grid_size(grid_size)

    if cache_record and cache_record.out_of_date_since.nil?
      # We have an in date cache record
    else
      # Remove the old out-of-date cache if we had one
      cache_record.destroy if cache_record

      # Generate the new cache
      cache_record = generate_cache_clusters(grid_size)

      cache_record.save()

    end

    return cache_record.cached_occurrence_clusters
  end

  # Generate the cache for all species, at all grid levels, that have out-of-date caches
  # and have a total of equal to or more than cache_occurrence_clusters_threshold records.

  def self.generate_cache_for_all_species cache_occurrence_clusters_threshold

    logger.info "Generating cache for all #{Species.count} of our species (as necessary)"

    # Update the cache if necessary for all species with total occurrences > CACHE_OCCURRENCE_CLUSTERS_THRESHOLD
    Species.all.each do |sp|
      if sp.occurrences.count >= cache_occurrence_clusters_threshold
        logger.info "Generating cache for: #{sp.common_name}"
        Occurrence::GRID_SIZES.each do |grid_size|
          sp.get_or_generate_cached_clusters(grid_size)
        end
      else
        logger.info "Skipping species #{sp.common_name}"
      end
    end

    logger.info "Finished generating cache for all species"

    nil
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

  def get_occurrence_feature_properties cluster, geom_feature, options
    bbox = options[:bbox]

    common = {
      description: "",
      occurrence_type: "dotgriddetail"
    }

    output = {}

    output.merge!(common)


    if cluster.attributes.has_key? "cluster_size"

      # get our envelope for this cluster...
      cluster_envelope_geom = nil
      if cluster.cluster_envelope.is_a? String
        cluster_envelope_geom = Occurrence.rgeo_factory_for_column(:location).parse_wkt(cluster.cluster_envelope)
      else
        cluster_envelope_geom = cluster.cluster_envelope
      end

      cluster_envelope_bbox = RGeo::Cartesian::BoundingBox.new(Occurrence.rgeo_factory_for_column(:location))
      cluster_envelope_bbox.add(cluster_envelope_geom)

      # get our buffered envelope for this cluster...
      buffered_cluster_envelope_geom = nil
      if cluster.buffered_cluster_envelope.is_a? String
        buffered_cluster_envelope_geom = Occurrence.rgeo_factory_for_column(:location).parse_wkt(cluster.buffered_cluster_envelope)
      else
        buffered_cluster_envelope_geom = cluster.buffered_cluster_envelope
      end
      buffered_cluster_envelope_bbox = RGeo::Cartesian::BoundingBox.new(Occurrence.rgeo_factory_for_column(:location))
      buffered_cluster_envelope_bbox.add(buffered_cluster_envelope_geom)

      output.merge!({
        classificationTotals: [],
        point_radius: Math::log2(cluster.cluster_size.to_i).floor + MIN_FEATURE_RADIUS,
        stroke_width: Math::log2(cluster.cluster_size.to_i).floor + MIN_FEATURE_RADIUS,
        cluster_size: cluster.cluster_size.to_i,
        title: "#{cluster.cluster_size} points here",
        vettingBounds: {
          minlon: buffered_cluster_envelope_bbox.min_x,
          maxlon: buffered_cluster_envelope_bbox.max_x,
          minlat: buffered_cluster_envelope_bbox.min_y,
          maxlat: buffered_cluster_envelope_bbox.max_y,
        },
        gridBounds: {
          minlon: cluster_envelope_bbox.min_x,
          maxlon: cluster_envelope_bbox.max_x,
          minlat: cluster_envelope_bbox.min_y,
          maxlat: cluster_envelope_bbox.max_y,
        }
      })

      major_classification = nil
      major_classification_count = 0

      Classification::STANDARD_CLASSIFICATIONS.each do |classification|
        classification_count = cluster.attributes["#{classification}_count"].to_i
        classification_contentious_count = cluster.attributes["contentious_#{classification}_count"].to_i

        if classification_count > major_classification_count
          major_classification = classification
          major_classification_count = classification_count
        end

        if classification_count > 0
          output[:classificationTotals] << {
            label: classification,
            total: classification_count,
            contentious: classification_contentious_count,
            isGrandTotal: false
          }
        end

      end

      if output[:classificationTotals].length > 1
        output[:classificationTotals] << {
          label: "TOTAL",
          total: cluster.cluster_size.to_i,
          contentious: cluster.contentious_count.to_i,
          isGrandTotal: true,
        }
      end

      major_classification_properties = Classification::serializable_hash(major_classification)

      output[:stroke_color]    = major_classification_properties[:fill_color]
      output[:fill_color]      = major_classification_properties[:fill_color]

    else
      output.merge!(cluster.serializable_hash)
      output.merge!({
        point_radius: MIN_FEATURE_RADIUS,
        stroke_width: MIN_FEATURE_RADIUS,
        cluster_size: 1,
        title: "1 point here",
        occurrenceCoord: { lat: geom_feature.y, lon: geom_feature.x }
      })
    end

    output
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

  # Generates the cache record for the given grid size.
  # Returns the generated cache record

  def generate_cache_clusters(grid_size)

    cluster_result = occurrences.where_not_invalid.cluster(grid_size: grid_size).select_classification_totals

    # Create a cache record for this species

    cache_record = self.species_cache_records.new()
    cache_record.grid_size = grid_size
    cache_record.cache_generated_at = Time.now

    cluster_result.each do |cluster|
      rec = cache_record.cached_occurrence_clusters.new()
      rec.cluster_size              = cluster.attributes['cluster_size']
      rec.cluster_centroid          = cluster.attributes['cluster_centroid']
      rec.cluster_envelope          = cluster.attributes['cluster_envelope']
      rec.buffered_cluster_envelope = cluster.attributes['buffered_cluster_envelope']
      rec.contentious_count         = cluster.attributes['contentious_count']

      Classification::ALL_CLASSIFICATIONS.each do |classification|
        classification_count = "#{classification}_count"
        method = "#{classification}_count=".to_sym
        val = cluster.attributes[classification_count]
        rec.send(method, val)

        cont_classification_count = "contentious_#{classification}_count"
        method = "contentious_#{classification}_count=".to_sym
        val = cluster.attributes[cont_classification_count]
        rec.send(method, val)
      end

    end

    cache_record

  end

end
