require 'thor'
require 'amp4e_ldap_tool/cisco_amp'
require 'amp4e_ldap_tool/ldap_scrape'
require 'amp4e_ldap_tool'

module Amp4eLdapTool
  class CLI < Thor
    
    desc "amp --[groups|computers|policies]", "Gets groups, computer, and/or policies from AMP"
    long_desc <<-LONGDESC
    groupsync amp will get a list of groups, policies, and computers from AMP,
    with the specified options above.

    For example the following command will fetch the list of computers from amp:

    > $ groupsync amp -c
    LONGDESC
    method_option :computers, aliases: "-c"
    method_option :groups, aliases: "-g"
    method_option :policies, aliases: "-p"
    def amp
      display_resources(Amp4eLdapTool::CiscoAMP.new, options)
    end

    desc "ldap --[groups|computers|distinguished]", "Gets groups, computer, and/or distinguished names from LDAP"
    long_desc <<-LONGDESC
    groupsync ldap will get a list of groups, distinguished names, and computers from AMP,
    with the specified options above.

    For example the following command will fetch the list of computers from ldap:

    > $ groupsync ldap -c
    LONGDESC
    method_option :computers, aliases: "-c"
    method_option :groups, aliases: "-g"
    method_option :distinguished, aliases: "-d"
    def ldap
      ldap = Amp4eLdapTool::LDAPScrape.new 
      puts ldap.groups unless options[:groups].nil?
      ldap.entries.each {|entry| puts entry.dnshostname} unless options[:computers].nil?
      ldap.entries.each {|entry| puts entry.dn} unless options[:distinguished].nil?
    end
 
    long_desc <<-LONGDESC
    Moves a computer to a specified group, requires the new group GUID.

    For example the following command will move a specific computer(00000000-0000-0000-0000-000000000000)
    to group(11111111-1111-1111-1111-111111111111).
    
    > $ groupsync move 00000000-0000-0000-0000-000000000000 11111111-1111-1111-1111-111111111111
    LONGDESC
    desc "move PC GUID", "Moves a PC to a specified group, requires the new groups GUID"
    def move(computer, new_guid)
      amp = Amp4eLdapTool::CiscoAMP.new
      puts amp.move_computer(computer, new_guid)
    end

    long_desc <<-LONGDESC
    Creates a group with the specified name.

    For example the following command will create a group with the name ExampleGroup:

    > $ groupsync create ExampleGroup
    LONGDESC
    desc "create NAME", "Creates a group with the name of NAME"
    method_option :desc, aliases: "-d"
    def create(name)
      amp = Amp4eLdapTool::CiscoAMP.new
      puts amp.create_group(name).name unless options[:desc]
      puts amp.create_group(name, options[:desc]).name if options[:desc]
    end

    long_desc <<-LONGDESC
    Moves a specified group under a new parent.

    For example the following command will move the group(00000000-0000-0000-0000-000000000000)
    under parent(11111111-1111-1111-1111-111111111111):

    > $ groupsync move_group 00000000-0000-0000-0000-000000000000 11111111-1111-1111-1111-111111111111
    LONGDESC
    desc "move_group GUID PARENT", "Moves a group under a new parent"
    def move_group(guid, parent_guid)
      amp = Amp4eLdapTool::CiscoAMP.new
      puts amp.update_group(guid, parent_guid)
    end

    long_desc <<-LONGDESC
    Shows a dry run of changes, and prompts to execute:

    For example the following command will execute a dry run:

    > $ groupsync make_changes -a
    LONGDESC
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
