#===============================================================================
# Copyright (c) 2017 Cisco and/or its affiliates
#
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
#
#   1. Redistributions of source code must retain the above copyright notice, 
#      this list of conditions and the following disclaimer.
#
#   2. Redistributions in binary form must reproduce the above copyright 
#      notice, this list of conditions and the following disclaimer in the 
#      documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
#===============================================================================

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
      parent_name = ldap.parent(entry.dn)
      unless adj[computername].nil?
        if adj[computername][:parent] != parent_name
          puts "moving computer..."
          amp.update_computer(adj[computername][:object].guid, adj[parent_name][:object].guid)
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
