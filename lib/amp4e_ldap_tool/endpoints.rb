module Amp4eLdapTool
  module AMP
    class Computer
      attr_accessor :name, :guid, :link, :active,
                    :group_guid, :policy, :os

      def initialize(json)
        @name = json["hostname"]
        @guid = json["connector_guid"]
        @link = { computer: json["links"]["computer"],
                    trajectory: json["links"]["trajectory"],
                    groups: json["links"]["group"]}
        @active = json["active"]
        @policy = { name: json["policy"]["name"],
                    guid: json["policy"]["guid"] }
        @group_guid = json["group_guid"]
        @os = json["operating_system"]
      end
    end
    
    class Group
      attr_accessor :name, :description, :guid, :parent, :link

      def initialize(json)
        @name = json["name"]
        @guid = json["group_guid"]
        @description = json["description"]
        @link = json["links"]["group"]
        @parent = (json["ancestry"].nil?) ? {} :
            {name: json["ancestry"].first["name"],
             guid: json["ancestry"].first["guid"]}
      end
    end

    class Policy
      attr_accessor :name, :description, :guid, :product, :default,
                    :serial_number, :link

      def initialize(json)
        @name = json["name"]
        @guid = json["guid"]
        @description = json["description"]
        @product = json["product"]
        @default = json["default"]
        @serial_number = json["serial_number"]
        @link = json["links"]["policy"]
      end
    end
  end
end
