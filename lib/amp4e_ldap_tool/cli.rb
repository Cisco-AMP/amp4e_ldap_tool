require 'thor'
require 'amp4e_ldap_tool/cisco_amp'
require 'amp4e_ldap_tool/ldap_scrape'
require 'amp4e_ldap_tool'

module Amp4eLdapTool
  class CLI < Thor
    
    desc "fetch SOURCE --[groups|computers]", "Gets groups and/or computers from SOURCE"
    long_desc <<-LONGDESC
    groupsync fetch SOURCE will get a list of groups and computers from SOURCE,
    you must specify with --groups (-g), or --computers (-c).

    for example the following command will fetch the list of computers from
    amp:

    > $ groupsync fetch AMP -c
    LONGDESC
    method_option :groups, aliases: "-g"
    method_option :policies, aliases: "-p"
    method_option :computers, aliases: "-c"
    method_option :distinguished, aliases: "-d"
    def fetch(source)
      case source.downcase.to_sym
      when :amp
        display_resources(Amp4eLdapTool::CiscoAMP.new, options)
      when :ldap
        ldap = Amp4eLdapTool::LDAPScrape.new 
        ldap.scrape_ldap_entries.each do |entry| 
          puts entry.to_ldif unless options[:distinguished].nil?
          puts ldap.get_groups(entry.dn) unless options[:groups].nil?
          puts ldap.get_computer(entry.dn) unless options[:computers].nil?
        end
      else
        puts "I couldn't understand SOURCE, for now specify amp or ldap"
      end
    end
    
    desc "move PC GUID", "Moves a PC to a specified group, requires the new groups GUID"
    def move(computer, new_guid)
      amp = Amp4eLdapTool::CiscoAMP.new
      puts amp.move_computer(computer, new_guid)
    end

    desc "create NAME", "Creates a group with the name of NAME"
    method_option :desc, aliases: "-d"
    def create(name)
      amp = Amp4eLdapTool::CiscoAMP.new
      puts amp.create_group(name) unless options[:desc]
      puts amp.create_group(name, options[:desc]) if options[:desc]
    end

    desc "apply_changes", "Shows a dry run of changes"
    def apply_changes
      amp       = Amp4eLdapTool::CiscoAMP.new
      ldap      = Amp4eLdapTool::LDAPScrape.new
      amp_data  = { computers: amp.get(:computers), groups: amp.get(:groups) }
      ldap_data = { groups: [], computers: [] }
      entities  = ldap.scrape_ldap_entries
      
      entities.each do |entity|
        ldap_data[:computers] << ldap.get_computer(entity.dn)
        ldap_data[:groups]    << ldap.get_groups(entity.dn)
      end

      Amp4eLdapTool.compare(amp_data, ldap_data)
      answer = ask("Do you want to continue?", limited_to: ["y","n"])
      if (answer == "y")
        make_changes(amp, amp_data, entities)
      end
    end

    private
    def make_changes(amp_data, ldap_data)
      #TODO wait for ratelimit changes
    end

    def format(groups, computers)
      string = StringIO.new
      groups.each do |x|
        printf(string, "Group: %-20s Parent: %-20s\n", x.name, x.parent[:name])
      end
      string
    end

    def display_resources(amp, options)
      options.keys.each do |endpoints|
        puts "#{endpoints}:"
        amp.get(endpoints).each do |endpoint|
          puts endpoint.name
        end
      end
    end
  end
end
