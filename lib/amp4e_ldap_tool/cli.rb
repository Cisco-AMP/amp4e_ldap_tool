require 'thor'
require 'amp4e_ldap_tool/cisco_amp'

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
    method_option :computers, aliases: "-c"
    def fetch(source)
      case source.downcase
      when "amp"
        amp = Amp4eLdapTool::CiscoAMP.new
        puts amp.get("computers", "hostname") unless options[:computers].nil?
        puts amp.get("groups", "name") unless options[:groups].nil?
      when "ldap"
      
      else
        puts "I couldn't understand SOURCE, for now specify amp or ldap"
      end
    end
    
    desc "move PC GUID", "Moves a PC to a specified group, requires the new groups GUID"
    def move(computer, new_guid)
      amp = Amp4eLdapTool::CiscoAMP.new
      puts amp.move_computer(computer, new_guid)
    end
  end
end
