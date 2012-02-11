require 'sinatra/base'

class TurnServer < Sinatra::Base
  ID_PATTERN = "([a-f0-9]{24})"
  PLAYER_NAME_PATTERN = "([a-zA-Z][a-zA-Z0-9]+)"
  
  # Protect access to either admin or any registered player.
  # If the player can't log in (or isn't admin) then 
  def validate_for_access(access)
    raise unless [:admin, :any_player].include? access
    
    player = authorized_player_for_access access
    if player
      player
    else
      response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
      halt [401, { error: "Not authorized" }.to_json]
    end
  end

  # Returns the player if they are authorized for the access level requested.
  def authorized_player_for_access(access)
    raise unless [:admin, :any_player].include? access
    
    @auth ||= Rack::Auth::Basic::Request.new request.env
    if @auth.provided? && @auth.basic? && @auth.credentials
      username, password = @auth.credentials
      case access
        when :admin
          username == 'admin' and Player.authenticate(username, password)
        when :any_player
          Player.authenticate username, password
      end
    else
      nil
    end
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
  

  run! unless test?
end







