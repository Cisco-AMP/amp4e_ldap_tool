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
  module AMP
    class Computer
      attr_accessor :name, :guid, :link, :active,
                    :group_guid, :policy, :os

      def initialize(json)
        @name       = json["hostname"]
        @guid       = json["connector_guid"]
        @active     = json["active"]
        @group_guid = json["group_guid"]
        @os         = json["operating_system"]
        @link       = { computer: json["links"]["computer"],
                        trajectory: json["links"]["trajectory"],
                        group: json["links"]["group"]}
        @policy     = { name: json["policy"]["name"],
                        guid: json["policy"]["guid"] }
      end
    end
    
    class Group
      attr_accessor :name, :description, :guid, :parent, :link

      def initialize(json)
        @name         = json["name"]
        @guid         = json["guid"]
        @description  = json["description"]
        @parent       = (json["ancestry"].nil?) ? {} :
                        {name: json["ancestry"].first["name"],
                         guid: json["ancestry"].first["guid"]}
      end
    end

    class Policy
      attr_accessor :name, :description, :guid, :product, :default,
                    :serial_number, :link

      def initialize(json)
        @name          = json["name"]
        @guid          = json["guid"]
        @description   = json["description"]
        @product       = json["product"]
        @default       = json["default"]
        @serial_number = json["serial_number"]
        @link          = json["links"]["policy"]
      end
    end
  end
end
