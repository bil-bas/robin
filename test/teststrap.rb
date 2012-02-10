require_relative '../lib/smash_and_grab_server'
require 'bacon'
require 'rack/test'
require 'set'
require 'bacon/rr'

set :environment, :test
    
# Load env from file when testing.
load File.expand_path('../../heroku_env.rb', __FILE__)

def app
  Sinatra::Application
end
 
module Bacon
  class Context
    include Rack::Test::Methods
    
    def body
      JSON.parse last_response.body
    end
  end
end

class Should
  def have_same_elements_as(data)
    Set.new(self.to_a) == Set.new(data.to_a)
  end
end