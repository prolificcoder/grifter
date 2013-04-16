require 'yaml'

require_relative 'log'

class Hapi
  module Configuration
    def recursive_symbolize hash
      hash.inject({}) do |h, (k,v)|
        h[k.intern] = case v
                      when Hash
                        recursive_symbolize v
                      else
                        v
                      end
        h
      end
    end

    def load_config_file options={}
      options = {config_file: 'hapi.yml'}.merge(options)
      Log.debug "Loading config file '#{options[:config_file]}'"
      unless File.exist?(options[:config_file])
        raise "No such config file: '#{options[:config_file]}'"
      end
      hash = YAML.load_file(options[:config_file])
      symbolized = recursive_symbolize(hash)
      normalize_config(symbolized, options)
    end

    #this method ensure the config hash has everything we need to instantiate the service objects
    def normalize_config config, options={}
      unless ((config.is_a? Hash) &&
              (config.has_key? :services) &&
              (config[:services].is_a? Hash) &&
              (config[:services].length > 0))
        raise HapiConfigurationError.new ":services block not found in configuration"
      end

      #fill out services block entirely for each service
      config[:services].each_pair do |service_name, service_config|
        service_config[:name] = service_name.to_s
       #setup port config
       unless service_config[:port]
         if service_config[:ssl]
           service_config[:port] = 443
         else
          service_config[:port] = 80
         end
       end

       #ssl config
       unless service_config[:ssl]
         service_config[:ssl] = false
       end

       #ignore_ssl_certificate
       unless service_config[:ignore_ssl_cert]
         service_config[:ignore_ssl_cert] = false
       end

       unless service_config[:base_uri]
         service_config[:base_uri] = ''
       end

      end

      #merge any environment overrides into the service block
      if options[:environment]
        unless config[:environments] && config[:environments][options[:environment]]
          raise HapiConfigurationError.new "No such environment specified in config: '#{options[:environment]}'"
        end

        config[:environments][options[:environment]].each_pair do |service_name, service_overrides|
          config[:services][service_name].merge! service_overrides
        end
      end


      return config
    end
  end
end

class HapiConfigurationError < Exception
end
