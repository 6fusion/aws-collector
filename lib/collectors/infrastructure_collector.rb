require 'aws_helper'

class InfrastructureCollector
  include AWSHelper

  def instances
    all_regions.collect do |r|
      instances_for_region(r)
    end.compact.flatten
  end

  private

  def all_regions
    Clients.ec2.describe_regions.data.regions.map(&:region_name)
  end

  def instances_for_region(region)
    Resources.ec2(region).instances.entries
  end
end