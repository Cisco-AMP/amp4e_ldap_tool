require 'thor'
require 'amp4e_ldap_tool/cisco_amp'
require 'amp4e_ldap_tool/ldap_scrape'
require 'amp4e_ldap_tool'

module Amp4eLdapTool
  class CLI < Thor
    
    desc "amp --[groups|computers|policies]", "Gets groups, computer, and/or policies"
    long_desc <<-LONGDESC
    groupsync amp will get a list of groups, policies, and computers from AMP,
    you must specify with --groups (-g), --computers (-c), or --policies (-p).

    for example the following command will fetch the list of computers from
    amp:

    > $ groupsync  amp -c
    LONGDESC
    desc "amp", "Gets computers and/or groups from AMP"
    method_option :computers, aliases: "-c"
    method_option :groups, aliases: "-g"
    method_option :policies, aliases: "-p"
    def amp
      display_resources(Amp4eLdapTool::CiscoAMP.new, options)
    end

    desc "ldap --[groups|computers|distinguished]", "Gets groups, computer, and/or distinguished names"
    long_desc <<-LONGDESC
    groupsync ldap will get a list of groups, distinguished names, and computers from AMP,
    you must specify with --groups (-g), --computers (-c), or --distinguished (-d).

    for example the following command will fetch the list of computers from
    ldap:

    > $ groupsync  ldap -c
    LONGDESC
    desc "ldap", "Gets computers and/or groups from LDAP"
    method_option :computers, aliases: "-c"
    method_option :groups, aliases: "-g"
    method_option :distinguished, aliases: "-d"
    def ldap
      ldap = Amp4eLdapTool::LDAPScrape.new 
      puts ldap.groups unless options[:groups].nil?
      ldap.entries.each do |entry| 
        puts entry.dn unless options[:distinguished].nil?
        puts entry.dnshostname unless options[:computers].nil?
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
      puts amp.create_group(name).name unless options[:desc]
      puts amp.create_group(name, options[:desc]).name if options[:desc]
    end

    desc "move_group GUID PARENT", "Moves a group under a new parent"
    def move_group(guid, parent_guid)
      amp = Amp4eLdapTool::CiscoAMP.new
      puts amp.update_group(guid, parent_guid)
    end

    desc "make_changes", "Shows a dry run of changes, and prompts to execute"
    method_option :apply, aliases: "-a"
    def make_changes
      amp   = Amp4eLdapTool::CiscoAMP.new
      ldap  = Amp4eLdapTool::LDAPScrape.new

      Amp4eLdapTool.dry_run(amp, ldap)
      answer = "n"
      answer = ask("Do you want to continue?", limited_to: ["y","n"]) if options[:apply]
      if (answer == "y")
        Amp4eLdapTool.push_changes(amp, ldap)
      end
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
