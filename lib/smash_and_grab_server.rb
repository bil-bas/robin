require 'bundler/setup'

require 'sinatra'
require 'json'
require 'mongoid'

module SmashAndGrab
  NAME = "Smash and Grab"
  VERSION = "0.0.1"
  VALID_GAME_MODES = ['coop-baddies', 'coop-goodies', 'pvp']
end

SEED_CHARS = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a + [".", "/"]

# Connect to the database.
raise "MONGOLAB_URI unset" unless ENV['MONGOLAB_URI']
database_name = ENV['MONGOLAB_URI'][/[^\/]+$/]
Mongoid.configure do |config| 
  config.master = Mongo::Connection.from_uri(ENV['MONGOLAB_URI']).db database_name
end

class Player
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :name, type: String # Should be an index.
  field :password, type: String
  field :email, type: String
  has_and_belongs_to_many :games
  
  validates_uniqueness_of :name,  message: "Player already exists with this name."
  validates_uniqueness_of :email, message: "Player already exists with this email."
end

class Game
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :scenario, type: String
  field :players, type: Array
  field :mode, type: String
  field :initial, type: String # Essentially, this is the .sgl file.
  has_and_belongs_to_many :player # Well, 2 :)
  embeds_many :turns
  
  def create_turn?(number) 
    (number == 0 || turns.where(number: number - 1)).exists? &&
         !turns.where(number: number).exists?
  end  
end

class Turn
  include Mongoid::Document
  include Mongoid::Timestamps

  field :actions, type: String # List of actions.
  embedded_in :game
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
  return bad_request("missing player1") unless params[:player1] 
  return bad_request("missing player2") unless params[:player2] 
  return bad_request("missing mode") unless params[:mode] 
  unless SmashAndGrab::VALID_GAME_MODES.include? params[:mode] 
    return bad_request("invalid mode") 
  end
  
  players = Player.includes(name: [params[:player1], params[:player2]])
  game = Game.new scenario: params[:scenario], initial: params[:initial],
                  mode: params[:mode]
  game.insert
  
  players.each do |player|
    player.games << game  
    player.update
  end
  
  { 
      id: game.id, 
      scenario: params[:scenario],
      started: game.created_at,
      players: players.map {|p| p.name },
      mode: params[:mode]
  }.to_json  
end

post '/games/:game_id/:turn' do |game_id, turn|  
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
                  game: game_id, number: turn
  turn.insert
  
  game.turns << turn
  game.update
  
  # TODO: notify opponent.

  200 
end
