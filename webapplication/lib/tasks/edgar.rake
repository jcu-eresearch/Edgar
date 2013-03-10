desc "Edgar's custom rake tasks"
namespace :edgar do

  desc "Tasks associated with our caching"
  namespace :cache do

    desc "Generates cache for all species with out of date caches. You can provide an argument, " +
         "+cache_occurrence_clusters_threshold+, to limit caching to only species with greater than or " +
         "equal number of occurrences to cache_occurrence_clusters_threshold. Default " +
         "cache_occurrence_clusters_threshold is Species::CACHE_OCCURRENCE_CLUSTERS_THRESHOLD " +
         "(see docs for value of constant)."
    task :generate, [:cache_occurrence_clusters_threshold] => [:environment] do |t, args|

      # Default the cache_occurrence_clusters_threshold to CACHE_OCCURRENCE_CLUSTERS_THRESHOLD
      args.with_defaults(cache_occurrence_clusters_threshold: Species::CACHE_OCCURRENCE_CLUSTERS_THRESHOLD )

      Rails.logger.info "Generating the cache with cache_occurrence_clusters_threshold " +
                  "of #{args[:cache_occurrence_clusters_threshold]}"

      Species.generate_cache_for_all_species(args[:cache_occurrence_clusters_threshold].to_i)

    end

    desc "Destroy all cache records."
    task :destroy, [] => [:environment] do |t, args|

      Rails.logger.info "Deleting the cache..."

      # Delete all the species cache records
      SpeciesCacheRecord.delete_all
      # Delete all the cached occurrence clusters
      CachedOccurrenceCluster.delete_all

      Rails.logger.info "Cache deleted!"

    end
  end

  desc "Tasks associated generally with the DB"
  namespace :db do

    desc "Wipes the content of the DB tables, then seeds the DB with " +
         "some required data. The seed data includes the ALA source and some " +
         "species. By default the DB seed populates the DB with small species (small no. of occurrences). " +
         "Specify +small_or_large+ as large to seed with DB with larger species."
    task :wipe_and_seed, [:small_or_large] => [:environment] do |t, args|

      # Default the db wipe to only prefill with small species.
      args.with_defaults(small_or_large: "small")

      path_to_importer = Rails.configuration.path_to_importer
      path_to_importer_db_wipe = File.join(path_to_importer, "bin", "db_wipe")

      case(args[:small_or_large])
      when "small"

        # Destroy the cache before we proceed
        Rake::Task["edgar:cache:destroy"].invoke

        # Note: Need to be in the same dir as the config file, as the importer's db_wipe
        # includes the config file relative to current location.
        puts `cd #{path_to_importer} && #{path_to_importer_db_wipe} --go`
      when "large"

        # Destroy the cache before we proceed
        Rake::Task["edgar:cache:destroy"].invoke

        # Note: Need to be in the same dir as the config file, as the importer's db_wipe
        # includes the config file relative to current location.
        puts `cd #{path_to_importer} && #{path_to_importer_db_wipe} --go --big`
      else
        raise ArgumentError, "args invalid. :small_or_large should be 'small' or 'large', was: #{args[:small_or_large].inspect}"
      end

    end
  end

  desc "Tasks associated with the importer"
  namespace :importer do
    desc "Imports the species and occurrence data from ALA"
    task :import_from_ala, [] => [:environment] do |t, args|

      path_to_importer = Rails.configuration.path_to_importer
      path_to_importer_ala_db_update = File.join(path_to_importer, "bin", "ala_db_update")
      path_to_importer_config_file = File.join(path_to_importer, "config.json")

      puts `#{path_to_importer_ala_db_update} #{path_to_importer_config_file}`

    end
  end
end
