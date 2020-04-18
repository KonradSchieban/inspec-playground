# frozen_string_literal: true

class GCPBaseCache < Inspec.resource(1)
  name 'GCPBaseCache'
  desc 'The GCP Base cache resource is inherited by more specific cache classes (e.g. GCE, GKE):
       The cache is consumed by the CIS and PCI Google Inspec profiles:
       https://github.com/GoogleCloudPlatform/inspec-gcp-cis-benchmark'
  attr_reader :gke_locations

  def initialize(project: '')
    @gcp_project_id = project
    @gke_locations = []
  end

  protected

  def get_all_gcp_locations
    locations = inspec.google_compute_zones(project: @gcp_project_id).zone_names
    locations += inspec.google_compute_regions(project: @gcp_project_id)
                       .region_names
    locations
  end

end

class GKECache < GCPBaseCache
  name 'GKECache'
  desc 'The GKE cache resource contains functions consumed by the CIS/PCI Google profiles:
       https://github.com/GoogleCloudPlatform/inspec-gcp-cis-benchmark'
  attr_reader :gke_locations, :gce_zones

  @@cached_gke_clusters = []
  @@gke_clusters_cached = false

  def initialize(project: '', gke_locations: [])
    @gcp_project_id = project
    @gke_locations = if gke_locations.join.empty?
                       get_all_gcp_locations
                     else
                       gke_locations
                     end
  end

  def get_gke_clusters_cache()
    if is_gke_cached == false
      set_gke_clusters_cache
    end
    @@cached_gke_clusters
  end

  def is_gke_cached
    @@gke_clusters_cached
  end

  def set_gke_clusters_cache()
    @@cached_gke_clusters = []
    collect_gke_clusters_by_location(@gke_locations)
    @@gke_clusters_cached = true
  end

  private

  def collect_gke_clusters_by_location(gke_locations)
    gke_locations.each do |gke_location|
      inspec.google_container_clusters(project: @gcp_project_id,
                                       location: gke_location).cluster_names
            .each do |gke_cluster|
        @@cached_gke_clusters.push({ cluster_name: gke_cluster, location: gke_location })
      end
    end
  end
end

class GCECache < Inspec.resource(1)
  name 'GCECache'
  desc 'The GCE cache resource contains functions consumed by the CIS/PCI Google profiles:
       https://github.com/GoogleCloudPlatform/inspec-gcp-cis-benchmark'
  attr_reader :gke_locations, :gce_zones

  @@cached_gce_instances = []
  @@gce_instances_cached = false

  def initialize(project: '', gce_zones: [])
    @gcp_project_id = project
    @gce_zones = if gce_zones.join.empty?
                   inspec.google_compute_zones(project: @gcp_project_id).zone_names
                 else
                   gce_zones
                 end
  end

  def get_gce_instances_cache()
    if is_gce_cached == false
      set_gce_instances_cache
    end
    @@cached_gce_instances
  end

  def is_gce_cached
    @@gce_instances_cached
  end

  def set_gce_instances_cache()
    @@cached_gce_instances = []
    # Loop/fetch/cache the names and locations of GKE clusters
    @gce_zones.each do |gce_zone|
      inspec.google_compute_instances(project: @gcp_project_id, zone: gce_zone)
            .instance_names.each do |instance|
        @@cached_gce_instances.push({ name: instance, zone: gce_zone })
      end
    end
    # Mark the cache as full
    @@gce_instances_cached = true
    @@cached_gce_instances
  end
end

class GcpCache < Inspec.resource(1)
  name 'gcp_cache'
  desc 'The GCP cache resource contains functions consumed by the CIS/PCI Google profiles:
       https://github.com/GoogleCloudPlatform/inspec-gcp-cis-benchmark'
  attr_reader :gke_locations, :gce_zones

  @@cached_gce_instances = []
  @@cached_gke_clusters = []
  @@gke_clusters_cached = false
  @@gce_instances_cached = false

  def initialize(project: '')
    @gcp_project_id = project
    @gke_locations = []
    @gce_zones = []
  end

  def get_gke_clusters_cache()
    if @@gke_clusters_cached == true
      @@cached_gke_clusters
    else

    end
  end

  def get_gce_instances_cache()
    @@cached_gce_instances
  end

  def is_gke_cached
    @@gke_clusters_cached
  end

  def is_gce_cached
    @@gce_instances_cached
  end


  def set_gke_clusters_cache(gcp_gke_locations)
    unless @@gke_clusters_cached == true
      # Reset the list of cached clusters
      @@cached_gke_clusters = []
      begin
        # If we weren't passed a specific list/array of zones/region names from
        # inputs, search everywhere
        @gke_locations = if gcp_gke_locations.join.empty?
                           get_all_gcp_locations
                         else
                           gcp_gke_locations
                         end

        # Loop/fetch/cache the names and locations of GKE clusters
        collect_gke_clusters_by_location(gcp_gke_locations)

        # Mark the cache as full
        @@gke_clusters_cached = true
      rescue NoMethodError
        # During inspec check, the mock transport connection doesn't set up a
        # gcp_compute_client method
      end
    end
  end

  def get_gce_instances(gce_zones)
    unless @@gce_instances_cached == true
      # Set the list of cached intances
      @@cached_gce_instances = []
      begin
        # If we weren't passed a specific list/array of zone names from inputs,
        # search everywhere
        @gce_zones = if gce_zones.join.empty?
                       inspec.google_compute_zones(project: @gcp_project_id).zone_names
                     else
                       gce_zones
                     end

        # Loop/fetch/cache the names and locations of GKE clusters
        @gce_zones.each do |gce_zone|
          inspec.google_compute_instances(project: @gcp_project_id, zone: gce_zone)
                .instance_names.each do |instance|
            @cached_gce_instances.push({ name: instance, zone: gce_zone })
          end
        end
        # Mark the cache as full
        @@gce_instances_cached = true
      rescue NoMethodError
        # During inspec check, the mock transport connection doesn't set up a
        # gcp_compute_client method
      end
    end
    # Return the list of clusters
    @@cached_gce_instances
  end

  private

  def get_all_gcp_locations
    locations = inspec.google_compute_zones(project: @gcp_project_id).zone_names
    locations += inspec.google_compute_regions(project: @gcp_project_id)
                       .region_names
    locations
  end

  def collect_gke_clusters_by_location(gke_locations)
    gke_locations.each do |gke_location|
      inspec.google_container_clusters(project: @gcp_project_id,
                                       location: gke_location).cluster_names
            .each do |gke_cluster|
        @@cached_gke_clusters.push({ cluster_name: gke_cluster, location: gke_location })
      end
    end
  end
end
