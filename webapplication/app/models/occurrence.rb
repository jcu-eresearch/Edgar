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
  attr_readonly :basis, :classification, :contentious, :date, :location, :occurrence_basis, :source_classification, :source_id, :source_record_id, :species_id, :uncertainty

  belongs_to :species
  belongs_to :source

  before_destroy :prevent_destroy

  private

  def prevent_destroy
    errors.add(:base, "Can't destroy an occurrence")
    false
  end
end
