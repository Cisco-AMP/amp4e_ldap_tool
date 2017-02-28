require "amp4e_ldap_tool/version"
require "amp4e_ldap_tool/errors"
require "amp4e_ldap_tool/cisco_amp"
require "amp4e_ldap_tool/ldap_scrape"

module Amp4eLdapTool
  def self.tree(amp, ldap)
    amp_left = StringIO.new
    amp_right = StringIO.new
    amp[:groups].each do |computer|
      
    end 
  end


end
