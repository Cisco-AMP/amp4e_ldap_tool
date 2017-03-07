require "amp4e_ldap_tool/version"
require "amp4e_ldap_tool/errors"
require "amp4e_ldap_tool/cisco_amp"
require "amp4e_ldap_tool/ldap_scrape"

module Amp4eLdapTool
  def self.dry_run(amp, ldap)
    groups = []
    amp_groups = amp.get(:groups)
    ldap.groups.each do |group|
      found = amp_groups.find {|g| g.name == group }
      if found.nil?
        puts "CREATE GROUP: #{group}"
        groups << group
      end
    end

    ldap.groups.each do |group|
      parent = ldap.parent(group)
      unless parent.nil?
        puts "UPDATE GROUP: #{group}, PARENT: #{parent}"
      end
    end

    computer = amp.get(:computers)
    ldap.entries do |entry|
      parent = ldap.parent(entry.dn)
      if groups.include?(parent)
        puts "MOVE PC #{entry.dnshostname.first}, GROUP: #{parent}"
      end
    end
  end


  def self.push_changes(amp, ldap)
    amp_groups = amp.get(:groups)
    ldap.groups.each do |group|
      found =  amp_groups.find {|g| g.name = group }
      if found.nil?
        amp.create_group(group)
      end
    end

    amp_groups = amp.get(:groups)
    ldap.groups.each do |group|
      parent = ldap.parent(group)
      unless parent.nil?
        amp_parent = amp_groups.find { |e| e.name == parent }
        amp_group  = amp_groups.find { |e| e.name == group }
        amp.update_group(amp_group.guid, amp_parent.guid)
      end
    end

    #3. Move Computers
    amp_pcs = amp.get(:computers)
    ldap.entries.each do |entry|
      amp_pc    = amp_pcs.find {|p| p.name == entry.dnshostname.first}
      unless amp_pc.nil?
        parent    = ldap.parent(entry.dn)
        amp_group = amp_groups.find {|g| g.name == parent}
        unless amp_pc.group_guid == amp_group.guid
          amp.update_computer(amp_pc.guid, amp_group.guid)
        end
      end
    end
  end
end
