class TurnServer < Sinatra::Base
  # Get a list of games owned by the player.
  get '/players/*/games' do |username|
    player = Player.where(username: username).first
    bad_request "no such player" unless player
       
    player.games.map(&:summary).to_json
  end 
end

