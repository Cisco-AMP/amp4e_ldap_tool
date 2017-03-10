require 'net/http'
require 'yaml'
require 'amp4e_ldap_tool/errors'
require 'amp4e_ldap_tool/endpoints'
require 'json'

module Amp4eLdapTool
  GUID = /\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/
  X_RATELIMIT_REMAINING = 'x-ratelimit-remaining'
  X_RATELIMIT_RESET = 'x-ratelimit-reset'

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
      body = { parent_group_guid: parent }
      response = send(patch, url, body)
    end

    def create_group(group_name, desc = "Imported from LDAP")
      url = URI(@base_url + "/#{@version}/groups/")
      post = Net::HTTP::Post.new(url)
      body = { name: group_name, email: @email,
               description: desc }
      send(post, url, body)
    end

    def make_list(computers, groups)
      adj = {}
      groups.each do |group|
        adj[group.name] = { object: group, parent: group.parent[:name] }
      end

      computers.each do |pc|
        group = groups.find{ |g| g.guid = pc.group_guid }
        adj[pc.name.downcase] = { object: pc, parent: group.name }
      end
      adj
    end

    private
    
    def send(http_request, url, body = {})
      http_request.basic_auth(@third_party, @api_key)
      http_request.set_form_data(body) unless body.empty?
      check_response do
        Net::HTTP.start(url.hostname, url.port) do |http|
          http.request(http_request)
        end
      end
    end

    def check_response
      begin
        response = yield
        response_head = response.to_hash
        response_body = JSON.parse(response.body) 
        
        case response.msg.downcase.tr(" ","_").to_sym
        when :ok
          response_notification = response.body
        when :accepted, :created
          response_notification = response.msg
        when :too_many_requests
          raise AMPTooManyRequestsError
        when :bad_request
          raise AMPBadRequestError.new(msg: response_body["errors"])
        when :unauthorized
          raise AMPUnauthorizedError.new(msg: response_body["errors"])
        else
          raise AMPResponseError.new(msg: "code: " + response.msg + " body: " + response.body)
        end
      rescue AMPTooManyRequestsError
        sleep_seconds = response_head[Amp4eLdapTool::X_RATELIMIT_RESET].to_i
        puts "Ratelimit Reached, sleeping for #{sleep_seconds} second(s)"
        sleep(sleep_seconds)
        retry
      end
      response_notification
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

    def validate_guid(guids)
      guids.each do |guid|
        if Amp4eLdapTool::GUID.match(guid).nil?
          raise AMPInvalidFormatError
        end
      end
    end

    def confirm_config(config)
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
