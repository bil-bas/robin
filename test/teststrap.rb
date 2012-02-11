require 'bacon'
require 'rack/test'
require 'set'
require 'bacon/rr'
  
ENV['RACK_ENV'] = "test"
  
require_relative '../lib/smash_and_grab_server'

JSON_TYPE = "application/json;charset=utf-8"  
ID_PATTERN = /^[0-9a-f]{24}$/

def clean_database
  Player.delete_all
  Game.delete_all 
  Map.delete_all
  #Action.delete_all # Action is a part of a Game.
end 

clean_database

def app
  TurnServer
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

