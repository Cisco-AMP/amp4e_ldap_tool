require "amp4e_ldap_tool/version"
require "amp4e_ldap_tool/errors"
require "amp4e_ldap_tool/cisco_amp"
require "amp4e_ldap_tool/ldap_scrape"
require "terminal-table"

module Amp4eLdapTool

  def self.dry_run(amp, ldap)
    #TODO validate input
    data = {created_groups: [], group_moves: [], pc_moves: []}
    adj = amp.make_list(amp.get(:computers), amp.get(:groups))
    ldap.groups.each do |group|
      if adj[group].nil?
        data[:created_groups] << [group, "nil"]
        adj[group] = { object: nil, parent: nil }
      end
      unless adj[group][:parent] == ldap.parent(group)
        data[:group_moves] << [group, adj[group][:parent], ldap.parent(group)]
        adj[group][:parent] = ldap.parent(group) 
      end
    end
    counter = {}
    ldap.entries.each do |entry|
      computername = entry.dnshostname.first.downcase
      unless adj[computername].nil?
        if adj[computername][:parent] != ldap.parent(entry.dn)
          old_name = adj[computername][:parent]
          new_name = ldap.parent(entry.dn)
          if counter[old_name].nil?
            counter[old_name] = {new_name => 1}
          else
            counter[old_name][new_name].nil? ? counter[old_name][new_name] = 1 
                                             : counter[old_name][new_name] += 1
          end
        end
      end
    end
    counter.keys.each do |old_name|
      counter[old_name].keys.each do |new_name|
        data[:pc_moves] << [counter[old_name][new_name], old_name, new_name]
      end
    end
    generate_table(data)
  end

  def self.push_changes(amp, ldap)
    #TODO validate input
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

  private

  def self.generate_table(table_data)
    #TODO validate input
    puts Terminal::Table.new(title: "Group Creates", rows: table_data[:created_groups], 
                             headings: ["Group Name", "Parent Group"])
    puts Terminal::Table.new(title: "Group Moves", rows: table_data[:group_moves],
                             headings: ["Group", "Old Parent", "New Parent"])
    puts Terminal::Table.new(title: "Computer Moves", rows: table_data[:pc_moves],
                             headings: ["# of computers", "from group", "to group" ])
  end

end
