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
    adj = amp.make_list(amp.get(:computers), amp.get(:groups))
    ldap.groups.each do |group|
      if adj[group].nil?
        puts "creating group..."
        g = amp.create_group(group)
        adj[group] = { object: g, parent: g.parent[:name]  }
      end
      unless adj[group][:parent] == ldap.parent(group)
        puts "updating group parent..."
        amp.update_group(adj[group][:object].guid, adj[ldap.parent(group)][:object].guid)
        adj[group][:parent] = ldap.parent(group) 
      end
    end
    ldap.entries.each do |entry|
      computername = entry.dnshostname.first.downcase
      unless adj[computername].nil?
        if adj[computername][:parent] != ldap.parent(entry.dn)
          puts "adding computer..."
          amp.update_computer(adj[computername][:object].guid, adj[adj[computername][:parent]][:object].guid)
        end
      end
    end
  end
end
