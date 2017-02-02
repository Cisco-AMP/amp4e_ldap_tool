require 'net/http'
require 'yaml'
require 'amp4e_ldap_tool/errors'
require 'json'

module Amp4eLdapTool
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
    
    def get(endpoint, value)
      url = URI(@base_url + "/#{@version}/#{endpoint}")
      get = Net::HTTP::Get.new(url)
      get.basic_auth(@third_party, @api_key)
      response = Net::HTTP.start(url.hostname, url.port) do |http|
        http.request(get)
      end
      check_response(response, value)
    end

    private

    def check_response(response, value)
      output = []
      case response.message
      when "OK"
        output = scrape_response(response.body, value)
      when "Unauthorized"
        raise AMPResponseError.new(msg: "Third_party/API credentials appear to be invalid")
      else
        raise AMPResponseError
      end
      output
    end

    def scrape_response(message, value)
      output = []
      parse = JSON.parse(message)
      parse["data"].each do |item|
        output << item[value]
      end
      output
    end

    def confirm_config(config)
      raise AMPConfigError if config[:amp][:host].nil?
      raise AMPConfigError if config[:amp][:email].nil?
      raise AMPConfigError if config[:amp][:api][:third_party].nil?
      raise AMPConfigError if config[:amp][:api][:key].nil?
      raise AMPConfigError if config[:amp][:api][:version].nil?
    end
  end
end
