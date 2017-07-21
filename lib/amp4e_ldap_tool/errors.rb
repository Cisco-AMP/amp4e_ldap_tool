#===============================================================================
# Copyright (c) 2017 Cisco and/or its affiliates
#
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
#
#   1. Redistributions of source code must retain the above copyright notice, 
#      this list of conditions and the following disclaimer.
#
#   2. Redistributions in binary form must reproduce the above copyright 
#      notice, this list of conditions and the following disclaimer in the 
#      documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
#===============================================================================

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

  class AMPTooManyRequestsError < StandardError
    def initialize(msg: "The ratelimit has been excedded")
      super
    end
  end

  class AMPBadURIError < StandardError
    def initialize(msg: "The amp:host in your config file contains an invalid hostname")
      super
    end
  end

  class AMPInvalidFormatError < ArgumentError
    def initialize(msg: "The GUID provided does not follow the correct format")
      super
    end
  end

  class AMPResponseError < StandardError
    def initialize(msg: "The AMP Server returned a non-OK response")
      super
    end
  end

  class AMPUnauthorizedError < AMPResponseError
    def initialize(msg: "Third_party/API credentials appear to be invalid")
      super
    end
  end

  class AMPBadRequestError < AMPResponseError
    def initialize(msg: "A Bad request was made to the server")
      super
    end
  end
end
