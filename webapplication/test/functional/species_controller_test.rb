require 'test_helper'

class SpeciesControllerTest < ActionController::TestCase
  setup do
    @emu = species(:emu)
    @only_has_one_deleted_vetting = species(:only_has_one_deleted_vetting)
    @occurrence_factory = Occurrence.rgeo_factory_for_column(:location)
    @vetting_factory = Vetting.rgeo_factory_for_column(:area)
  end

  test "should get index" do
    get :index
    assert_response :success
  end

  test "should get map" do
    get :map
    assert_response :success
  end

  test "should get occurrences as GeoJSON" do
    get(:occurrences, id: @emu, format: :json)
    assert_response :success

    geom = RGeo::GeoJSON.decode(@response.body, :json_parser => :json)
    assert_kind_of(RGeo::GeoJSON::FeatureCollection, geom)

  end

  test "should get occurrences as WKT" do
    get(:occurrences, id: @emu, format: :text)
    assert_response :success

    features = @occurrence_factory.parse_wkt(@response.body)
    assert_kind_of(RGeo::Feature::GeometryCollection, features)
  end

  test "should get vettings as GeoJSON" do
    get(:vettings, id: @emu, format: :json)
    assert_response :success

    geom = RGeo::GeoJSON.decode(@response.body, :json_parser => :json)
    assert_kind_of(RGeo::GeoJSON::FeatureCollection, geom)
  end

  test "should get vettings as GeoJSON with custom limit (limit: 1)" do
    get(:vettings, id: @emu, format: :json, limit: 1)
    assert_response :success

    geom = RGeo::GeoJSON.decode(@response.body, :json_parser => :json)
    assert_kind_of(RGeo::GeoJSON::FeatureCollection, geom)

    assert_equal(1, geom.size())
  end

  test "should get vettings as GeoJSON with custom limit (limit: 2)" do
    get(:vettings, id: @emu, format: :json, limit: 2)
    assert_response :success

    geom = RGeo::GeoJSON.decode(@response.body, :json_parser => :json)
    assert_kind_of(RGeo::GeoJSON::FeatureCollection, geom)

    assert_equal(2, geom.size())
  end

  test "shouldn't get deleted vettings" do
    get(:vettings, id: @only_has_one_deleted_vetting, format: :json)
    assert_response :success

    geom = RGeo::GeoJSON.decode(@response.body, :json_parser => :json)
    assert_kind_of(RGeo::GeoJSON::FeatureCollection, geom)

    assert_equal(0, geom.size())
  end

  test "should get vettings as WKT" do
    get(:vettings, id: @emu, format: :text)
    assert_response :success

    features = @vetting_factory.parse_wkt(@response.body)
    assert_kind_of(RGeo::Feature::GeometryCollection, features)
  end

end
