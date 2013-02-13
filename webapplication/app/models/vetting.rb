# == Schema Information
#
# Table name: vettings
#
#  id             :integer          not null, primary key
#  user_id        :integer          not null
#  species_id     :integer          not null
#  comment        :text             not null
#  classification :classification   not null
#  created        :datetime         not null
#  modified       :datetime         not null
#  deleted        :datetime
#  ignored        :datetime
#  last_ala_sync  :datetime
#

class Vetting < ActiveRecord::Base
  # The SRID (projection format) this model uses
  SRID = 4326

  attr_accessible :classification, :comment, :area
  attr_readonly :classification, :comment, :area, :last_ala_sync, :species_id, :user_id

  belongs_to :species
  belongs_to :user

  before_destroy :prevent_destroy

  self.rgeo_factory_generator = RGeo::Geos.factory_generator
  set_rgeo_factory_for_column(:area, RGeo::Geographic.spherical_factory(srid: SRID))

  # Get the vettings that fall inside the bbox
  # [+bbox] an Array of floats (lat/lng degrees decimal) [w, s, e, n]

  def self.in_rect(bbox)
    w, s, e, n = *bbox.map { |v| v.to_f }

    where("area && ST_MakeEnvelope(?, ?, ?, ?, ?)", w, s, e, n, SRID)
  end

  # Get the vettings made by user_id

  def self.where_user_is(user_id)
    where('user_id = ?', user_id)
  end

  # Get the vettings made by users other than user_id

  def self.where_user_is_not(user_id)
    where('user_id != ?', user_id)
  end

  # Get the vettings that aren't deleted

  def self.where_not_deleted()
    where('deleted is NULL')
  end

  # Simplify an area, removing overlaps
  # Also ensures that result is a multipolygon

  def self.select_simplified_area(area_wkt)
    self.connection.execute(sanitize_sql_array(
      ["SELECT ST_AsText(ST_MULTI(ST_Buffer('%s', 0))) AS simplified_area", area_wkt]
    )).first["simplified_area"]
  end

  # Add user information into the vetting's json

  def serializable_hash(*args) 
    attrs = super(*args)
    attrs.
      merge({
        user: "#{user.fname} #{user.lname}"
      }).
      merge(Classification::serializable_hash(self.classification))
  end

  private

  def prevent_destroy
    errors.add(:base, "Can't destroy a vetting")
    false
  end

end
