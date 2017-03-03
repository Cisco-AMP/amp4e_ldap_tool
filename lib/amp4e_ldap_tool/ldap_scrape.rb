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
    
    # Prints out a list of groups from root -> lower
    def groups
      names = split_dn(dn); names.shift
      dn_paths = []
      temp_names = names.clone
      name_subgroups.each do
        name = temp_names.join(".")
        dn_paths << name
        temp_array.pop
      end
      dn_paths.uniq.reverse
    end

    #TODO Make it actually use the DN instead of dotted
    def get_parent(dn)
      full_computer_name = []
      parent_string = ''
      dn.split('.').each do |name|
        full_computer_name << name
      end
      
      full_computer_name.shift
      unless full_computer_name.empty?
        parent_string = full_computer_name.join(".")
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
