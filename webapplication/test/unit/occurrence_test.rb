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

require 'test_helper'

class OccurrenceTest < ActiveSupport::TestCase
  def setup
    @one = occurrences(:one)
    @two = occurrences(:two)
    @three = occurrences(:three)
  end

  test "Occurrence at Brisbane is north of occurrence at Sydney" do
    occurrence_at_brisbane = @two
    occurrence_at_sydney   = @one
    assert ( occurrence_at_brisbane.location.y > occurrence_at_sydney.location.y )
  end

  test "Clustering with a sufficiently large grid size reduces result count" do
    options = {}
    options[:grid_size] = 10.0
    results = Occurrence.cluster(options)

    assert(
      ( results.length < Occurrence.count ),
      "Clustering with a grid_size of 10.0 failed to result in a smaller set. " +
      "Clusters: #{results.length}. Occurrences: #{Occurrence.count}."
    )
  end

  test "Clustering with a sufficiently small grid size doesn't effect result count" do
    options = {}
    options[:grid_size] = 1.0
    results = Occurrence.cluster(options)

    assert_equal(
      results.length,
      Occurrence.count,
      "Clustering with a grid_size of 1.0 reduced the set size. This was unexpected. " +
      "If Occurrence fixtures have been added that are closer than 1.0 degrees decimal, " +
      "then this test is no longed valid. Adjust the grid size for this test accordingly. " +
      "Clusters: #{results.length}. Occurrences: #{Occurrence.count}."
    )
  end

  test "Clustering produces rows with +cluster_size+ and +cluster_centroid+" do
    options = {}
    options[:grid_size] = 10.0
    results = Occurrence.cluster(options)

    results.each do |el|
      assert(
        ( el.cluster_size.to_i > 0 ),
        "Clustering should have resulted in a cluster_size which is " +
        " a valid Integer greater than 0. Cluster location count " +
        "is: #{el.cluster_size.inspect}"
      )
      assert_not_nil(
        Occurrence.rgeo_factory_for_column(:location).parse_wkt(el.cluster_centroid),
        "Clustering produced an invalud cluster_centroid. cluster_centroid isn't valid WKT"
      )
    end
  end

  test "Clustering with grid_size and bbox produces rows with +cluster_size+ and +cluster_centroid+" do
    options = {}
    options[:grid_size] = 10.0
    options[:bbox] = "-180,-90,180,90"
    results = Occurrence.cluster(options)

    results.each do |el|
      assert(
        ( el.cluster_size.to_i > 0 ),
        "Clustering should have resulted in a cluster_size which is " +
        " a valid Integer greater than 0. Cluster location count " +
        "is: #{el.cluster_size.inspect}"
      )
      assert_not_nil(
        Occurrence.rgeo_factory_for_column(:location).parse_wkt(el.cluster_centroid),
        "Clustering produced an invalud cluster_centroid. cluster_centroid isn't valid WKT"
      )
    end
  end

  test "Normalise grid_size does what we expect" do
    assert_equal(10, Occurrence::normalise_grid_size(12))
    assert_equal(5, Occurrence::normalise_grid_size(6))
    assert_equal(1, Occurrence::normalise_grid_size(4.9))
    assert_equal(0.5, Occurrence::normalise_grid_size(0.5))
    assert_equal(0.5, Occurrence::normalise_grid_size(0.55))
    assert_equal(0.25, Occurrence::normalise_grid_size(0.3))
    assert_equal(0.1, Occurrence::normalise_grid_size(0.12))
    assert_equal(0.05, Occurrence::normalise_grid_size(0.06))
    assert_equal(Occurrence::MIN_GRID_SIZE_BEFORE_NO_CLUSTERING, Occurrence::normalise_grid_size(0.016))
    assert_equal(Occurrence::MIN_GRID_SIZE_BEFORE_NO_CLUSTERING, Occurrence::normalise_grid_size(Occurrence::MIN_GRID_SIZE_BEFORE_NO_CLUSTERING))
    assert_equal(nil, Occurrence::normalise_grid_size(0.0001))
  end

end
