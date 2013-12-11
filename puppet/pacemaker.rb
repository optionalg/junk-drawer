# Pacemaker Facter Facts
require "rexml/document"

pacemaker = REXML::Document.new Facter::Util::Resolution.exec('/usr/sbin/pcs status xml').to_s

pacemaker.elements.each('crm_mon/resources/group') do |group|
  fact_prefix = "pacemaker_#{group.attributes['id']}"
  group.elements.each do |resource|
    Facter.add("#{fact_prefix}_#{resource.attributes['id']}") do
      setcode do
        active_nodes = []
        resource.elements.each do |node|
          active_nodes << node.attributes['name']
        end
        active_nodes
      end
    end
  end
end
