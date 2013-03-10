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
      Species.generate_cache_for_all_species(args[:cache_occurrence_clusters_threshold].to_i)

    end
  end
end
