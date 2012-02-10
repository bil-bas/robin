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

get '/' do
  { name: SmashAndGrab::NAME, version: SmashAndGrab::VERSION }.to_json
end

get '/players/:name/games' do |name|
  player = Player.where(name: name).first
  { games: player.games }.to_json
end

get '/games/:game_id' do |game_id|
  game = Game.find(game_id)
  game.to_json
end

get '/games/:game_id/:turn' do |game_id, turn|
  game = Game.where(id: game_id).first
 
  turn = Turn.turn turn
end

# POST

post '/games' do
  return bad_request("missing scenario") unless params[:scenario] 
  return bad_request("missing initial") unless params[:initial] 
  return bad_request("missing players") unless params[:players] 
  return bad_request("missing mode") unless params[:mode] 
  unless SmashAndGrab::VALID_GAME_MODES.include? params[:mode] 
    return bad_request("invalid mode") 
  end
  
  player_names = params[:players].split ";"
  players = Player.includes name: player_names
  raise unless players.size == 2
  
  game = Game.new scenario: params[:scenario], initial: params[:initial],
                  mode: params[:mode]
  game.insert
  
  players.each do |player|
    player.games << game  
    player.update
  end
  
  { 
      id: game.id, 
      scenario: game.scenario,
      started_at: game.created_at,
      players: player_names,
      mode: game.mode
  }.to_json  
end

post '/games/:game_id/:turn' do |game_id, turn_number|  
  return bad_request("missing actions") unless params[:actions] 
  return bad_request("missing name") unless params[:name]
  #return bad_request("missing password") unless params[:password]
  
  #player = Player.where(name: params[:name]).first
  #return bad_request "bad username or password" unless player 
  
  #  return bad_request "bad username or password"
  #end
  #unless player and player.password == params[:password].crypt(SEED_CHARS.sample(2).join)
  #  
  #end
 
  game = Game.find game_id
  return bad_request("game not found", game_id: game_id) unless game
  
  # Accept a turn that hasn't already been uploaded and that is immediately after the last uploaded turn.
  turn = turn.to_i
  unless game.create_turn? turn
    return bad_request("turn sent out of sequence", game_id: game_id, turn: turn) 
  end
  
  turn = Turn.new actions: params[:actions], created_at: Time.now,
                  game: game_id, number: turn_number
  turn.insert
  
  game.turns << turn
  game.update
  
  # TODO: notify opponent.

  { success: "turn sent" }.to_json 
end
