# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

ala_source = Source.new()
ala_source.name = "ALA"
ala_source.save()

cockatoo = Species.new()
cockatoo.common_name = "Palm Cockatoo"
cockatoo.scientific_name = "Probosciger aterrimus"
cockatoo.save()
