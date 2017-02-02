require 'thor'

module Amp4eLdapTool
  class CLI < Thor
    
    desc "fetch SOURCE", "Gets all information from SOURCE (AMP, LDAP)"
    long_desc <<-LONGDESC
    groupsync fetch SOURCE will get a list of groups and computers from SOURCE,
    however if you are only after groups or computers, you can specify with
    --groups (-g), or --computers (-c).

    for example the following command will fetch the list of computers from
    amp:

    > $ groupsync fetch AMP -c
    LONGDESC
    method_option :groups, aliases: "-t" 
    method_option :computers, aliases: "-g"
    def fetch(source)
      case source
      when "AMP"
        
      when "LDAP"
      
      else
        puts "I couldn't understand the source"
      end
    end
  end
end
