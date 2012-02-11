require 'mongoid'

require_relative "models/player"
require_relative "models/game"
require_relative "models/action"
require_relative "models/map"

# Connect to the database.
database_uri = ENV['MONGOLAB_URI'] || "mongodb://localhost:27017/test"
database_name = database_uri[/[^\/]+$/]
Mongoid.configure do |config| 
  config.master = Mongo::Connection.from_uri(database_uri).db database_name
end