module Robin
  class Settings
    public
    # Load config from a file, replacing possible environment variables
    # from the environment.
    def initialize(settings_file)
      yaml = File.read settings_file
      
      # Replace environment variables in the settings.
      yaml.gsub!(/([A-Z][A-Z0-9_]+)/) do |env|
        ENV[env] || env
      end
      
      @settings = YAML::load yaml
    end

    public
    # Read a settings value.
    #
    # @example
    #    left = config[:keys, :player1, :left]
    def [](*keys)      
      keys.inject @settings do |settings, key|
        settings[key.to_s]
      end
    end
  end
end