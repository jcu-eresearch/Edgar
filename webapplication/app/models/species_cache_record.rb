class SpeciesCacheRecord < ActiveRecord::Base
  attr_readonly :species_id, :grid_size, :cache_generated_at

  # Allow the out_of_date_since to be updated
  attr_accessible :out_of_date_since

  # A species will have many species cache records

  belongs_to :species

  # If this species cache record is deleted, remove all
  # associated cached occurrence clusters.
  #
  # We could do it like this:
  #   has_many :cached_occurrence_clusters, dependent: destroy
  #
  # But instead we'll do it using the delete_all (which will
  # immediately delete all our children via SQL). They won't
  # have a chance to run their associated destroy callbacks.
  # This will be much faster, as we won't instantiate our children.
  #
  # Note: As callbacks aren't honored, neither are dependency rules.
  # If cached_occurrence_clusters ever end up with children,
  # this line should be changed to a destroy callback.

  has_many :cached_occurrence_clusters, dependent: :delete_all

end
