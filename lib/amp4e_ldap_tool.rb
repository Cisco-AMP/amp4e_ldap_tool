require "amp4e_ldap_tool/version"
require "amp4e_ldap_tool/errors"
require "amp4e_ldap_tool/cisco_amp"
require "amp4e_ldap_tool/ldap_scrape"

module Amp4eLdapTool
  def self.compare(amp, ldap = nil)
    puts amp[:computers]
      
  end


end
