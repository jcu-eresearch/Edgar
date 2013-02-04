class Source < ActiveRecord::Base
  attr_accessible :last_import_time, :name, :url
end
