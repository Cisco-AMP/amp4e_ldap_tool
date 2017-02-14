require 'net/ldap'
require 'yaml'
require 'json'

module Amp4eLdapTool
  class LDAPScrape
    
    attr_reader :attributes, :filter, :domain, :full_name
    
    def initialize(filename = 'config.yml')
      cfg = YAML.load_file(filename)

      @attributes = cfg[:ldap][:schema][:attributes]
      @filter = Net::LDAP::Filter.eq('objectClass', cfg[:ldap][:schema][:filter])
      @domain = cfg[:ldap][:host]
      @full_name = make_distinguished(cfg[:ldap][:domain])

      @server = Net::LDAP.new(
        host: cfg[:ldap][:host],
        auth: {
          method: :simple,
          username: "#{cfg[:ldap][:credentials][:un]}@#{cfg[:ldap][:domain]}",
          password: cfg[:ldap][:credentials][:pw]}
      )
    end

    def scrape_ldap_entries
      entry_list = []
      @server.search(base: @full_name, filter: @filter, attributes: @attributes) do |entry|
        entry_list << entry
      end
      entry_list
    end

    def parse_dn(d_name)
      relative_names = []
      dn_paths = []
       
      d_name.split(',').each do |name|
        relative_names << name.split('=').last
      end

      temp_array = relative_names.reverse.clone
      relative_names.each do
        dn_paths << temp_array.inject { |glob, value| "#{value}.#{glob}" }
        temp_array.pop
      end
      dn_paths.reverse
    end
    
    def make_distinguished(domain_name)
      output = ''
      domain_name.split('.').each do |name|
        output << "dc=#{name},"
      end
      output.chomp(',')
    end
  end
end
