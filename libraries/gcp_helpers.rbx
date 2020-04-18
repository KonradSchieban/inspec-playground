# frozen_string_literal: false
require 'google_compute_zones'
# module Kstest for testing
module ::Kstest
  @some_var = "asdf"

  def self.sample_string(str)
    return str
  end

  def self.append_string(str1, str2)
    return str1 + str2
  end

  def self.play_with_member_var()
    return self.append_string(@some_var, "_appended")
  end

  def self.list_zones(gcp_project_id)
    return google_compute_zones(project: gcp_project_id)
  end
end

module ::GcpCache
  @is_gke_clusters_list_cached = false
  @gke_locations = []
  @gce_instances_cached = false
  @gce_zones = []
  @cached_gke_clusters = []

  def self. gke_list_cached?
    @is_gke_clusters_list_cached
  end

  def self.get_gke_clusters_list()
    @cached_gke_clusters
  end

  def self.set_gke_cache(google_container_clusters_retrieved, gke_locations)
    if is_gke_clusters_list_cached == false
      @gke_locations = if gcp_gke_locations.join.empty?
                         self.get_all_gcp_locations(gcp_project_id)
                       else
                         gcp_gke_locations
                       end

      # Loop/fetch/cache the names and locations of GKE clusters
      self.collect_gke_clusters_by_location(gcp_project_id, @gke_locations)

      # Mark the cache as full
      @is_gke_clusters_list_cached = true
    end
  end

  def self.collect_gke_clusters_by_location(google_container_clusters_retrieved, gke_locations)
    google_container_clusters_retrieved.cluster_names
      .each do |gke_cluster|

      @cached_gke_clusters.push({ cluster_name: gke_cluster,
                                  location: gke_location })
    end
  end
end

# module GcpHelpers contains auxiliary methods to accelerate
# retrieval of GCP objects
module ::GcpHelpers
  @gke_clusters_cached = false
  @gke_locations = []
  @gce_instances_cached = false
  @gce_zones = []
  @cached_gke_clusters = []

  def self.get_clusters_cached()
    @cached_gke_clusters
  end

  def self.check_cached()
    return @gke_clusters_cached
  end

  def self.get_all_gcp_locations(gcp_project_id)
    locations = google_compute_zones(project: gcp_project_id)
                .zone_names
    locations += google_compute_regions(project: gcp_project_id)
                 .region_names
    locations
  end

  def self.collect_gke_clusters_by_location(gcp_project_id, gke_locations)
    gke_locations.each do |gke_location|
      google_container_clusters(project: gcp_project_id,
                                location: gke_location).cluster_names
        .each do |gke_cluster|
        @cached_gke_clusters.push({ cluster_name: gke_cluster,
                                    location: gke_location })
      end
    end
  end

  def self.get_gke_clusters(gcp_project_id, gcp_gke_locations)
    unless @gke_clusters_cached == true
      # Reset the list of cached clusters
      @cached_gke_clusters = []
      begin
        # If we weren't passed a specific list/array of zones/region names from
        # inputs, search everywhere
        @gke_locations = if gcp_gke_locations.join.empty?
                           self.get_all_gcp_locations(gcp_project_id)
                         else
                           gcp_gke_locations
                         end

        # Loop/fetch/cache the names and locations of GKE clusters
        self.collect_gke_clusters_by_location(gcp_project_id, @gke_locations)

        # Mark the cache as full
        @gke_clusters_cached = true
      rescue NoMethodError
        # During inspec check, the mock transport connection doesn't set up a
        # gcp_compute_client method
      end
    end
    # Return the list of clusters
    @cached_gke_clusters
  end

  def get_gce_instances(gcp_project_id, gce_zones)
    unless @gce_instances_cached == true
      # Set the list of cached intances
      @cached_gce_instances = []
      begin
        # If we weren't passed a specific list/array of zone names from inputs,
        # search everywhere
        @gce_zones = if gce_zones.join.empty?
                       google_compute_zones(project: gcp_project_id).zone_names
                     else
                       gce_zones
                     end

        # Loop/fetch/cache the names and locations of GKE clusters
        @gce_zones.each do |gce_zone|
          google_compute_instances(project: gcp_project_id, zone: gce_zone)
            .instance_names.each do |instance|
            @cached_gce_instances.push({ name: instance, zone: gce_zone })
          end
        end
        # Mark the cache as full
        @gce_instances_cached = true
      rescue NoMethodError
        # During inspec check, the mock transport connection doesn't set up a
        # gcp_compute_client method
      end
    end
    # Return the list of clusters
    @cached_gce_instances
  end
end

::Inspec::DSL.include(GcpHelpers)
