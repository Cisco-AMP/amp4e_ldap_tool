require "amp4e_ldap_tool/version"
require "amp4e_ldap_tool/errors"
require "amp4e_ldap_tool/cisco_amp"
require "amp4e_ldap_tool/ldap_scrape"

module Amp4eLdapTool
  def self.dry_run(amp, ldap)
    adj = amp.make_list(amp.get(:computers), amp.get(:groups))
    ldap.groups.each do |group|
      if adj[group].nil?
        puts "Create Group: #{group}"
        adj[group] = { object: nil, parent: nil }
      end
      unless adj[group][:parent] == ldap.parent(group)
        puts "Update group: #{group}, parent: #{adj[group][:parent]} -> #{ldap.parent(group)}"
        adj[group][:parent] = ldap.parent(group) 
      end
    end
    ldap.entries.each do |entry|
      computername = entry.dnshostname.first.downcase
      unless adj[computername].nil?
        if adj[computername][:parent] != ldap.parent(entry.dn)
          puts "Move Computer: #{computername}, new parent: #{ldap.parent(entry.dn)}"
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
