module SmashAndGrab
  NAME = "Smash and Grab"
  VERSION = "0.0.1"
  VALID_GAME_MODES = ['coop-baddies', 'coop-goodies', 'pvp']
end

require_relative "model/player"
require_relative "model/game"
require_relative "model/turn"

SEED_CHARS = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a + [".", "/"]

# Connect to the database.
raise "MONGOLAB_URI unset" unless ENV['MONGOLAB_URI']
database_name = ENV['MONGOLAB_URI'][/[^\/]+$/]
Mongoid.configure do |config| 
  config.master = Mongo::Connection.from_uri(ENV['MONGOLAB_URI']).db database_name
end

after do
  content_type :json
end

def bad_request(message, data = {})
  [400, { error: message }.merge!(data).to_json]
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
  bad_request("game not found") unless game
  
  game.to_json
end

# Get a particular turn. Will hold until it is ready.
get '/games/:game_id/:turn' do |game_id, turn|
  game = Game.find(game_id) rescue nil
  
  return bad_request("game not found", game_id: game_id) unless game
  unless turn.is_a? Integer and turn >= 0
    return bad_request("bad turn number", game_id: game_id, turn: turn) 
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
  return bad_request("missing username") unless params[:username] 
  return bad_request("missing email") unless params[:email]
  
  return bad_request("player already exists") if Player.where(username: params[:username]).first
  
  Player.create username: params[:username], email: params[:email]
  
  { "success" => "player created" }.to_json
end  

# Create a new game.
post '/games' do
  return bad_request("missing scenario") unless params[:scenario] 
  return bad_request("missing initial") unless params[:initial] 
  return bad_request("missing players") unless params[:players] 
  return bad_request("missing mode") unless params[:mode] 
  unless SmashAndGrab::VALID_GAME_MODES.include? params[:mode] 
    return bad_request("invalid mode") 
  end
  
  player_names = params[:players].split ";"
  players = Player.includes username: player_names
  return bad_request("not all players exist") unless players.size == player_names.size
  
  game = Game.new scenario: params[:scenario], initial: params[:initial],
                  mode: params[:mode], players: players
  game.insert
  
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
  return bad_request("missing actions") unless params[:actions] 
  return bad_request("missing username") unless params[:username]
  #return bad_request("missing password") unless params[:password]
  
  #player = Player.where(username: params[:username]).first
  #return bad_request "bad username or password" unless player 
  
  #  return bad_request "bad username or password"
  #end
  #unless player and player.password == params[:password].crypt(SEED_CHARS.sample(2).join)
  #  
  #end
 
  game = Game.find(game_id) rescue nil
  return bad_request("game not found", game_id: game_id) unless game
  
  # Accept a turn that hasn't already been uploaded and that is immediately after
  # the last uploaded turn.
  turn_number = turn_number.to_i
  unless game.create_turn? turn_number
    return bad_request("turn sent out of sequence", game_id: game_id, turn: turn_number) 
  end
  
  game.turns.create actions: params[:actions]
  
  # TODO: notify opponent.

  { success: "turn accepted" }.to_json 
end
