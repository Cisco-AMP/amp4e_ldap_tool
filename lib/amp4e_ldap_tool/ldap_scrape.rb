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

require 'net/ldap'
require 'yaml'
require 'json'

module Amp4eLdapTool
  class LDAPScrape
    
    attr_reader :entries
    
    def initialize(filename = 'config.yml')
      cfg = YAML.load_file(filename)

      attributes = ["cn", "dnshostname"]
      base = make_dn(cfg[:ldap][:domain])
      filter = Net::LDAP::Filter.eq('objectClass', cfg[:ldap][:schema][:filter])
      server = Net::LDAP.new(
        host: cfg[:ldap][:host],
        auth: {
          method: :simple,
          username: "#{cfg[:ldap][:credentials][:un]}@#{cfg[:ldap][:domain]}",
          password: cfg[:ldap][:credentials][:pw]}
      )
      @entries = server.search(base: base, filter: filter, attributes: attributes) do |entry| 
        entry 
      end
    end
    
    def groups
      dn_paths = []
      @entries.each do |entry|
        names = split_dn(entry.dn); names.shift; names.reverse!
        temp_names = names.clone
        names.each do
          name = temp_names.inject{|glob, name| "#{name}.#{glob}"}
          dn_paths << name
          temp_names.pop
        end
      end
      dn_paths.uniq.reverse
    end

    def parent(entry_name)
      names = split_dn(entry_name)  if entry_name.include?("=")
      names = entry_name.split(".") if not entry_name.include?("=")
      names.shift
      unless names.empty?
        parent_string = names.join(".")
      end
    end
    
    private

    def make_dn(domain_name)
      output = ''
      domain_name.split('.').each do |name|
        output << "dc=#{name},"
      end
      output.chomp(',')
    end
    
    def split_dn(dn)
      names = []
      dn.split(",").each do |attribute|
        names << attribute.split("=").last
      end
      names
    end
  end
end
