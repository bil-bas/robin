require 'bundler/setup'
require 'json'

require_relative "robin/settings"

module Robin  
  # Allow config to be visible from anywhere.
  module Configuration
    class << self
      attr_accessor :config
    end
    
    # TODO: Use --config to get this.
    self.config = Settings.new "robin.yml"
  
    module Methods
      def config; Configuration.config; end
    end
    
    class << self    
      def included(base)
        base.send :include, Methods        
        base.send :extend, Methods
      end
    end    
  end
  
  include Robin::Configuration
end 

require_relative "robin/models"
require_relative "robin/routes"

# TODO: Read CLI arguments more sensibly.
Robin::Server.run! port: ARGV.find{|x| x.to_i > 0 }.to_i unless Robin::Server.test?