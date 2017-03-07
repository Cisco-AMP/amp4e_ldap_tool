require "amp4e_ldap_tool/version"
require "amp4e_ldap_tool/errors"
require "amp4e_ldap_tool/cisco_amp"
require "amp4e_ldap_tool/ldap_scrape"

module Amp4eLdapTool
  def self.dry_run(amp, ldap)
    groups = []
    amp_groups = amp.get(:groups)
    ldap.groups.each do |group|
      found = amp_groups.find(ifnone=nil) {|g| g.name == group }
      if found.nil?
        puts "CREATE GROUP: #{group}"
        groups << group
      end
    end

    ldap.groups.each do |group|
      parent = ldap.parent(group)
      unless parent.nil?
        found = groups.find(ifnone=nil) {|g| g == parent}
        unless found.nil?
          puts "UPDATE GROUP: #{group}, PARENT: #{parent}"
        end
      end
    end

    computers = amp.get(:computers)
    ldap.entries.each do |entry|
      found = computers.find(ifnone=nil) {|c| c.name.downcase == entry.dnshostname.first.downcase}
      unless  found.nil?
        parent = ldap.parent(entry.dn)
        group = groups.find(ifnone=nil) {|g| g == parent}
        if group.nil?
          #we're working with already created groups
          current_group = amp_groups.find(ifnone=nil) { |g| g.guid == found.group_guid }
          new_group = amp_groups.find(ifnone=nil) {|g| g.name == parent}
          puts current_group.name
          puts new_group.name
          unless current_group.guid == new_group.guid
            puts "MOVE PC: #{entry.dnshostname.first}, GROUP: #{parent}"
          end
        else
          puts "MOVE PC: #{entry.dnshostname.first}, GROUP: #{parent}"
        end
      end
    end
  end


  def self.push_changes(amp, ldap)
    amp_groups = amp.get(:groups)
    ldap.groups.each do |group|
      found =  amp_groups.find(ifnone=nil) {|g| g.name == group }
      if found.nil?
        puts "creating group..."
        amp.create_group(group)
      end
    end
    
    amp_groups = amp.get(:groups)
    ldap.groups.each do |group|
      parent = ldap.parent(group)
      unless parent.nil?
        amp_parent = amp_groups.find(ifnone=nil) { |e| e.name == parent }
        amp_group  = amp_groups.find { |e| e.name == group }
        unless amp_parent.guid == amp_group.parent[:guid]
          puts "updating group parents..."
          amp.update_group(amp_group.guid, amp_parent.guid)
        end
      end
    end
    
    amp_pcs = amp.get(:computers)
    ldap.entries.each do |entry|
      amp_pc    = amp_pcs.find {|p| p.name.downcase == entry.dnshostname.first.downcase}
      unless amp_pc.nil?
        parent    = ldap.parent(entry.dn)
        amp_group = amp_groups.find(ifnone=nil) {|g| g.name == parent}
        unless amp_pc.group_guid == amp_group.guid
          puts "adding computer..."
          amp.update_computer(amp_pc.guid, amp_group.guid)
        end
      end
    end
  end
end
