class TurnServer < Sinatra::Base
  # Get a list of games owned by the player.
  get %r{/players/#{PLAYER_NAME_PATTERN}/games} do |username|
    validate_for_access :any_player
    
    player = Player.where(username: username).first
    bad_request "no such player" unless player
       
    player.games.map(&:summary).to_json
  end 
end

