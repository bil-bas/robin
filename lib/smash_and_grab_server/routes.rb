require 'sinatra/base'

class TurnServer < Sinatra::Base
  ID_PATTERN = "([a-f0-9]{24})"
  PLAYER_NAME_PATTERN = "([a-zA-Z][a-zA-Z0-9]+)"
  
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

  after do
    content_type :json
  end
  
  # GET /
  get '/' do
    # Information about the server.
    { name: SmashAndGrab::NAME, version: SmashAndGrab::VERSION }.to_json
  end
  
  require_relative "routes/games_actions"
  require_relative "routes/games"
  require_relative "routes/players_games"
  require_relative "routes/players"
  

  run! unless ENV['RACK_TEST']
end







