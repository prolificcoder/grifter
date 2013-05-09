require_relative 'grifter/http_service'
require_relative 'grifter/configuration'
require_relative 'grifter/log'
require_relative 'grifter/blankslate'

class Grifter
  include Grifter::Configuration

  DefaultConfigOptions = {
    #TODO: service_config: nil,
    grift_globs: ['*_grifts/**/*_grifts.rb'],
    authenticate: false,
    load_from_config_file: true,
    services: {},
  }
  def initialize options={}
    options = DefaultConfigOptions.merge(options)
    @config = if options[:load_from_config_file]
                options.merge load_config_file(options)
              else
                options
              end

    #setup the services
    @services = []
    @config[:services].each_pair do |service_name, service_config|
      service = HTTPService.new(service_config)
      define_singleton_method service_name.intern do
        service
      end
      @services << service
    end

    #setup the grifter methods if any
    if @config[:grift_globs]
      @config[:grift_globs].each do |glob|
        Dir[glob].each do |grifter_file|
          load_grifter_file grifter_file
        end
      end
    end

    if @config[:authenticate]
      self.grifter_authenticate_do
    end
  end

  attr_reader :services

  def load_grifter_file filename
    Log.debug "Loading extension file '#{filename}'"
    anon_mod = Module.new
    #by evaling in a anonymous module, we protect this class's namespace
    load_dir = File.dirname(filename)
    $: << load_dir
    anon_mod.class_eval(IO.read(filename), filename, 1)
    $:.pop
    self.extend anon_mod
  end

  def run_script_file filename
    Log.info "Running data script '#{filename}'"
    raise "No such file '#{filename}'" unless File.exist? filename
    #by running in a anonymous class, we protect this class's namespace
    anon_class = BlankSlate.new(self)
    anon_class.instance_eval(IO.read(filename), filename, 1)
  end

  #calls all methods that end with grifter_authenticate
  def grifter_authenticate_do
    auth_methods = self.singleton_methods.select { |m| m =~ /grifter_authenticate$/ }
    auth_methods.each do |m|
      Log.debug "Executing a grifter_authentication on method: #{m}"
      self.send(m)
    end
  end
end