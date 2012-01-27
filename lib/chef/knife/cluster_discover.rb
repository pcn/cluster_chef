#
# Author:: Peter C. Norton (<pn@knewton.com>)
# Copyright:: Copyright (c) 2011 Infochimps, Inc
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# When dealing with a lot of clusters, discovering all clusters that
# exist is important.

# It is also useful to discover what dependencies may exist.  This
# command will be expanded to show what announces and discovers are
# used by various nodes.
# 
# to discover announces, we'll have to add a "record_usage" call that
# describes that a node/recipe uses a particular announcement.

# require File.expand_path(File.dirname(__FILE__)+"/knife_common.rb")
# require "cluster_chef"
# require "cluster_chef/compute"
# require "cluster_chef/server"
# require 'set'
# 
# class Chef
#   class Knife
#     class ClusterDiscover < Knife
#       include ClusterChef::KnifeCommon
#       deps do
#         ClusterChef::KnifeCommon.load_deps
#       end
# 
#       banner "knife cluster discover [CLUSTER_NAME [FACET_NAME]] (options)"
# 
#       def all_cluster_nodes() 
#         # Based on cluster_chef's discovery.rb
#         return @cluster_nodes if @cluster_nodes
#         @cluster_nodes = []
#         Chef::Search::Query.new.search(:node,"cluster_name:*") do |n|
#           @cluster_nodes.push(n)
#         end
#         @cluster_nodes
#       end
# 
#       def all_cluster_names()
#         return @cluster_names if @cluster_names
#         @cluster_names = []
#         all_cluster_nodes().each do |node|
#           begin
#             if node.cluster_name # "cluster_name" is a property used in a lot of node sub-properties
#               @cluster_names.push(node["cluster_name"])
#             end
#           rescue ArgumentError => e
#             Chef::Log.warn("Node #{node.name} doesn't have the attribute cluster_name.  Probably dead node:\n #{e}")
#           end
#         end
#         @cluster_names
#       end
# 
#       def all_cluster_facets(q_cluster_name)
#         # This essentially will get all info about all servers in a cluster.
#         # it will vivify the server, add it to the @aws_instance_hash and the 
#         # @servers_hash
#         return @clusters_hash[q_cluster_name] if @clusters_hash[q_cluster_name]
#         @clusters_hash[q_cluster_name] = []
#         facets = {}
#         all_cluster_nodes().each do |chef_node|
#           if chef_node["cluster_name"] && chef_node["facet_name"] && chef_node["facet_index"]
#             cluster_name = chef_node["cluster_name"]
#             facet_name   = chef_node["facet_name"]
#             facet_index  = chef_node["facet_index"]
#           elsif chef_node.name # ahh, desperation.  Old server instances, or broken instance
#             Chef::Log.warn("#{chef_node.name} doesn't have proper node attributes for a cluster node")
#             ( cluster_name, facet_name, facet_index ) = chef_node.name.split(/-/)
#           else
#             Chef::Log.warn("#{chef_node} can't be made into a cluster node. Bad node or bad search, perhaps?")            
#             next
#           end
#           if cluster_name == q_cluster_name
#             svr = ClusterChef::Server.get(cluster_name, facet_name, facet_index)
#             svr.chef_node = chef_node
#             if chef_node[:ec2] && chef_node.ec2.instance_id
#               @aws_instance_hash[ chef_node.ec2.instance_id ] = svr 
#             end
#             @clusters_hash[q_cluster_name].push(svr)
#             facets[facet_name] = 1
#           end
#         end
#         return facets.keys
#       end
# 
#       def display_cluster_info(cluster_name)
#         facets = all_cluster_facets(cluster_name)
#         # Get each server from fog?
#         table = []
#         facets = {}
#         @clusters_hash[cluster_name].each do |svr|
#           unless facets[svr.facet_name]
#             facets[svr.facet_name] = []
#           end
#           facets[svr.facet_name].push(svr)
#         end
#         # Sort by name and by facet index by breaking facets up into individual
#         # lists that are hash elements.  Then sort the hash elements by the index #
#         facets.keys.sort.each do |f|
#           facets[f].sort! {|a, b| a.facet_index <=> b.facet_index}
#           facets[f].each do |svr|
#             table.push({ :facet => svr.facet_name, 
#                          :index => svr.facet_index,
#                          :instance => svr.chef_node.ec2.instance_id,
#                          :public_ip => svr.chef_node.ec2.public_ipv4,
#                          :private_ip => svr.chef_node.ec2.local_ipv4
#                        })
#           end
#         end
#         Formatador.display_compact_table(table, [:facet, :index, :instance, :public_ip, :private_ip])
#       end
#       
#       def display_cluster_facet_info(cluster_name, facet_name)
#         facets = all_cluster_facets(cluster_name) # This populates the nodes
#         # Get each server from fog later?
#         table = []
#         f     = []
#         @clusters_hash[cluster_name].each do |svr|
#           if svr.facet_name.to_s == facet_name.to_s
#             f.push(svr)
#           end
#         end
#         # Sort the hash elements by the index #
#         f.sort! {|a, b| a.facet_index <=> b.facet_index}
#         f.each do |svr|
#           table.push({ :facet => svr.facet_name, 
#                        :index => svr.facet_index,
#                        :instance => svr.chef_node.ec2.instance_id,
#                        :public_ip => svr.chef_node.ec2.public_ipv4,
#                        :private_ip => svr.chef_node.ec2.local_ipv4
#                      })
#         end
#         Formatador.display_compact_table(table, [:facet, :index, :instance, :public_ip, :private_ip])
#       end
# 
#       def run
#         # die(banner) if @name_args.empty?
#         # configure_dry_run
# 
#         # are these two redundant? They are, nevertheless, convenient
#         @aws_instance_hash = {}
#         @clusters_hash = {}
# 
#         # Load the cluster/facet/slice/whatever
#         if @name_args.empty?
#           table = []
#           all_cluster_names.to_set.sort.each do |name|
#             table.push({ :cluster => name })
#           end
#           Formatador.display_compact_table(table, [:cluster])
#           exit
#         end
# 
#         (cluster_name, facet_name, slice_indexes) = *@name_args
#         
#         if cluster_name && facet_name
#           # diplay just the cluster and facet
#           display_cluster_facet_info(cluster_name, facet_name)
#           exit
#         elsif cluster_name
#           # display everything in the cluster
#           display_cluster_info(cluster_name)
#           exit
#         end
# 
#         # Display same
#         # display(all_cluster_names)
# 
#       end
#     end
#   end
# end
