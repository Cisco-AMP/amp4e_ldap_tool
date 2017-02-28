require 'net/http'
require 'yaml'
require 'amp4e_ldap_tool/errors'
require 'amp4e_ldap_tool/endpoints'
require 'json'

module Amp4eLdapTool
  GUID = /\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/
  RATE_HEADER = 'x-ratelimit-remaining'
  THROTTLE_THRESHOLD = 900 # * 4 seconds = 60 minutes of throttle

  class CiscoAMP
    
    attr_reader :base_url, :version, :email, :third_party, :api_key

    def initialize(config_file = "config.yml")
      config = YAML.load_file(config_file)
      confirm_config(config)
      @base_url = config[:amp][:host]
      @version = config[:amp][:api][:version]
      @email = config[:amp][:email]
      @third_party = config[:amp][:api][:third_party]
      @api_key = config[:amp][:api][:key]
    end
    
    def get(endpoint)
      url = URI(@base_url + "/#{@version}/#{endpoint}")
      get = Net::HTTP::Get.new(url)
      response = send(get, url)
      parse_response(response, endpoint.to_sym)
    end

    def update_computer(computer_guid, new_guid)
      validate_guid([computer_guid, new_guid])
      url = URI(@base_url + "/#{@version}/computers/#{computer_guid}")
      patch = Net::HTTP::Patch.new(url)
      body = { group_guid: new_guid }
      send(patch, url, body)
    end

    def update_group(group_guid, parent = nil)
      validate_guid([group_guid])
      url = URI(@base_url + "/#{@version}/groups/#{group_guid}/parent")
      patch = Net::HTTP::Patch.new(url)
      body = { parent_guid: parent }
      send(patch, url, body)
    end

    def create_group(group_name, desc = "Imported from LDAP")
      url = URI(@base_url + "/#{@version}/groups/")
      post = Net::HTTP::Post.new(url)
      body = { name: group_name, email: @email,
               description: desc }
      send(post, url, body)
    end

    private

    def send(http_request, url, body = {})
      http_request.basic_auth(@third_party, @api_key)
      http_request.set_form_data(body) unless body.empty?
      response = Net::HTTP.start(url.hostname, url.port) do |http|
        http.request(http_request)
      end
      check_response(response)
    end

    def check_response(response)
      throttle_check(response)
      
      output = ""
      parse = JSON.parse(response.body) 
      
      case response.code
      when "200"
        output = response.body
      when "201", "202"
        output = response.code
      when "400"
        raise AMPBadRequestError.new(msg: parse["errors"])
      when "401"
        raise AMPUnauthorizedError.new(msg: parse["errors"])
      else
        raise AMPResponseError.new(msg: "code: " + response.code + " body: " + response.body)
      end
      output
    end

    def parse_response(message, endpoint)
      endpoints = []
      parse = JSON.parse(message)
      parse["data"].each do |item|
        case endpoint
        when :computers
          endpoints << Amp4eLdapTool::AMP::Computer.new(item)
        when :groups
          endpoints << Amp4eLdapTool::AMP::Group.new(item)
        when :policies
          endpoints << Amp4eLdapTool::AMP::Policy.new(item)
        else
          raise AMPResponseError.new(msg: "Parsing GET error for #{endpoint}")
        end
      end
      endpoints
    end

    def throttle_check(response)
      parsed_response = JSON.parse(response.header)
      rate = parsed_response[Amp4eLdapTool::RATE_HEADER].to_i
      if (rate <= Amp4eLdapTool::THROTTLE_THRESHOLD)
        puts "The ratelimit threshold has been passed, throttling.."
        sleep(4)
      end
    end

    def validate_guid(guids)
      guids.each do |guid|
        if Amp4eLdapTool::GUID.match(guid).nil?
          raise AMPInvalidFormatError
        end
      end
    end

    def confirm_config(config)
      raise AMPConfigError if config[:amp][:email].nil?
      raise AMPConfigError if config[:amp][:api][:third_party].nil?
      raise AMPConfigError if config[:amp][:api][:key].nil?
      raise AMPConfigError if config[:amp][:api][:version].nil?
      begin
        Net::HTTP::Get.new(URI(config[:amp][:host]))
      rescue TypeError
        raise AMPBadURIError
      rescue ArgumentError
        raise AMPConfigError
      end
    end
  end
end
