require 'thor'
require 'amp4e_ldap_tool/cisco_amp'
require 'amp4e_ldap_tool/ldap_scrape'

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
    method_option :distingusihed, aliases: "-d"
    def fetch(source)
      case source.downcase
      when "amp"
        display_resources(Amp4eLdapTool::CiscoAMP.new, options)
      when "ldap"
        ldap = Amp4eLdapTool::LDAPScrape.new 
        ldap.scrape_ldap_entries.each { |entry| puts entry.dn } unless options[:distinguished].nil? 
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
    
    private

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
