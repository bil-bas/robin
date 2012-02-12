require 'bacon'
require 'rack/test'
require 'set'
require 'bacon/rr'
  
ENV['RACK_ENV'] = "test"
ENV['MONGOLAB_URI'] = "mongodb://localhost:27017/test"
ENV['GMAIL_SMTP_USER'] = "user@gmail.com"
ENV['GMAIL_SMTP_PASSWORD'] = "password"
  
require_relative '../lib/robin'

JSON_TYPE = "application/json;charset=utf-8"  
ID_PATTERN = /^[0-9a-f]{24}$/

def clean_database
  Robin::Models::Player.delete_all
  Robin::Models::Game.delete_all 
  Robin::Models::Map.delete_all
  #Action.delete_all # Action is a part of a Game.
end 

clean_database

def app
  Robin::Server
end
 
module Bacon
  class Context
    include Rack::Test::Methods
    
    def body
      JSON.parse last_response.body
    end
  end
end

