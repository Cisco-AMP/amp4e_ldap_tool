module Amp4eLdapTool
  class AMPConfigError < StandardError
    def initialize(msg: "The AMP section of the configuration file is not formatted properly" )
      super
    end
  end

  class LDAPConfigError < StandardError
    def initialize(msg: "The LDAP Section of the configuration file is not formatted properly")
      super
    end
  end

  class AMPResponseError < StandardError
    def initialize(msg: "The AMP Server returned a non-OK response")
      super
    end
  end

  class AMPBadURIError < StandardError
    def initialize(msg: "The amp:host in your config file contains an invalid hostname")
      super
    end
  end
  
  class AMPUnauthorizedError < AMPResponseError
    def initialize(msg: "Third_party/API credentials appear to be invalid")
      super
    end
  end
end
