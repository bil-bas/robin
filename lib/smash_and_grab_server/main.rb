module SmashAndGrab
  NAME = "Smash and Grab"
  VERSION = "0.0.1"
  VALID_GAME_MODES = ['coop-baddies', 'coop-goodies', 'pvp']
end

require_relative "model/player"
require_relative "model/game"
require_relative "model/turn"


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
  
  game_info = player.games.map do |game|
    {
        id: game.id,
        scenario: game.scenario,
        mode: game.mode,
        turns: game.turns.count,
     }
  end
     
  { games: game_info }.to_json
end

# Get a complete game, includeing all actions.
get '/games/:game_id' do |game_id|
  game = Game.find(game_id) rescue nil
  bad_request "game not found" unless game
  
  game.to_json
end

# Get a particular turn. Will hold until it is ready.
get '/games/:game_id/:turn' do |game_id, turn|
  game = Game.find(game_id) rescue nil
  
  bad_request("game not found", game_id: game_id) unless game
  unless turn.is_a? Integer and turn >= 0
    bad_request "bad turn number", game_id: game_id, turn: turn
  end
 
  until game.turns.count >= turn
    sleep 0.5
  end
  
  turn = game.turns[turn]
  
  turn.to_json
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
  
  { "success" => "player created" }.to_json
end  

# Create a new game.
post '/games' do
  bad_request "missing scenario" unless params[:scenario] 
  bad_request "missing initial" unless params[:initial] 
  bad_request "missing players" unless params[:players] 
  bad_request "missing mode" unless params[:mode] 
  unless SmashAndGrab::VALID_GAME_MODES.include? params[:mode] 
    bad_request "invalid mode" 
  end
  
  player = validate_player params 
  
  # Work out which players will be in the game.
  player_names = params[:players].split ";"
  unless player_names.include? player.username
    bad_request "username must be one of players"
  end
  players = Player.includes username: player_names # Ensure the order is correct.
  bad_request "not all players exist" unless players.size == player_names.size
  
  # Create the game.
  game = Game.create! scenario: params[:scenario], initial: params[:initial],
               mode: params[:mode], players: players
 
  { 
      id: game.id, 
      scenario: game.scenario,
      started_at: game.created_at,
      players: player_names,
      mode: game.mode
  }.to_json  
end

# Add a new turn to a game.
post '/games/:game_id/:turn_number' do |game_id, turn_number|  
  bad_request("missing actions") unless params[:actions] 
  
  validate_player params 
 
  # Check if the game exists.
  game = Game.find(game_id) rescue nil
  bad_request("game not found", game_id: game_id) unless game
  
  # Accept a turn that hasn't already been uploaded and that is immediately after
  # the last uploaded turn.
  turn_number = turn_number.to_i
  unless game.create_turn? turn_number
    bad_request "turn sent out of sequence", game_id: game_id, turn: turn_number
  end
  
  game.turns.create! actions: params[:actions]
  
  # TODO: notify opponent.

  { success: "turn accepted" }.to_json 
end
