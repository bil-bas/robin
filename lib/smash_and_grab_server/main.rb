module SmashAndGrab
  NAME = "Smash and Grab"
  VERSION = "0.0.1"
  VALID_GAME_MODES = ['coop-baddies', 'coop-goodies', 'pvp']
end

require_relative "model/player"
require_relative "model/game"
require_relative "model/action"


# Connect to the database.
raise "MONGOLAB_URI unset" unless ENV['MONGOLAB_URI']
database_name = ENV['MONGOLAB_URI'][/[^\/]+$/]
Mongoid.configure do |config| 
  config.master = Mongo::Connection.from_uri(ENV['MONGOLAB_URI']).db database_name
end

after do
  content_type :json
end

def validate_player(params)
  bad_request "missing username" unless params[:username] 
  bad_request "missing password" unless params[:password] 
  player = Player.where(username: params[:username]).first
  bad_request "bad username or password" unless player 
  bad_request "bad username or password" unless player.authenticate params[:password]
  
  player
end

def bad_request(message, data = {})
  halt [400, { error: message }.merge!(data).to_json]
end

# GET

# Information about the server.
get '/' do
  { name: SmashAndGrab::NAME, version: SmashAndGrab::VERSION }.to_json
end

# Get a list of games owned by the player.
get '/players/:username/games' do |username|
  player = Player.where(username: username).first
     
  player.games.map(&:summary).to_json
end

# Get a complete game, includeing all actions.
get '/games/:game_id' do |game_id|
  game = Game.find(game_id) rescue nil
  bad_request "game not found" unless game
  
  game.summary.merge(
      initial: game.initial,
      actions: game.actions.map(&:data)
  ).to_json
end

# Get actions for a game. Defaults to all actions, but can define :from
get '/games/:game_id/actions' do |game_id|
  from = params[:from].to_i # May be nil, which becomes 0
  
  game = Game.find(game_id) rescue nil 
  bad_request "game not found" unless game
  
  bad_request "bad action number" if from < 0
  
  game.actions[from..-1].map(&:data).to_json
end

# POST

# Create a player
post '/players' do
  bad_request "missing username" unless params[:username] 
  bad_request "missing password" unless params[:password] 
  bad_request "missing email" unless params[:email]
  
  bad_request "player already exists" if Player.where(username: params[:username]).first
  
  Player.create! username: params[:username], email: params[:email],
                 password: params[:password]
  
  { 
      "success" => "player created",
  }.to_json
end  

# Create a new game.
post '/games' do
  bad_request "missing scenario" unless params[:scenario] 
  bad_request "missing initial" unless params[:initial] 
  bad_request "missing players" unless params[:players] 
  bad_request "missing mode" unless params[:mode] 
  bad_request "invalid mode" unless SmashAndGrab::VALID_GAME_MODES.include? params[:mode] 
  
  player = validate_player params 
  
  # Work out which players will be in the game.
  player_names = params[:players].split ";"
  bad_request "username must be one of players" unless player_names.include? player.username

  players = Player.includes username: player_names # Ensure the order is correct.
  bad_request "not all players exist" unless players.size == player_names.size
  
  # Create the game.
  game = Game.create! scenario: params[:scenario], initial: params[:initial],
               mode: params[:mode], players: players
 
  { 
    success: "game created",
    id: game.id,
  }.to_json  
end

# Add a new action to a game.
post '/games/:game_id/actions' do |game_id| 
  bad_request "missing data" unless params[:data] 
  player = validate_player params 
 
  # Check if the game exists.
  game = Game.find(game_id) rescue nil
  bad_request "game not found" unless game

  # Check if the player validated is actually one of the players.
  bad_request "player not in game" unless game.players.include? player

  # Ignore actions after the game is finished.
  bad_request "game already complete" if game.complete?
  
  # Ignore actions sent, unless by the currently active player. 
  bad_request "action sent out of sequence" unless player == game.current_player
  
  game.actions.create! data: params[:data]
  
  message = if params[:end_game]
              # Close off the game if the action ended the game.
              game.complete = true
              game.update   
              # TODO: notify opponent via email and/or in next request?
              "game completed"
            elsif params[:end_turn]   
              # Advance to new turn if the action ended the turn. 
              game.turn += 1
              game.update    
              # TODO: notify opponent via email and/or in next request?
              "turn advanced"
            else 
              "action accepted"
            end
  
  { success: message }.to_json 
end
