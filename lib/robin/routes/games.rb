module Robin
class Server < Sinatra::Base
  # GET/POST /games and /games/*
  
  # Get a complete game, includeing all actions.
  get %r{/games/#{ID_PATTERN}} do |game_id|
    validate_for_access :any_player
    
    game = Models::Game.find(game_id) rescue nil
    bad_request "game not found" unless game
    
    game.summary.merge(
        actions: game.actions.map(&:data),
    ).to_json
  end

  # Create a new game.
  post '/games' do
    player = validate_for_access :any_player
    
    bad_request "missing map_id" unless params[:map_id]  
    bad_request "missing players" unless params[:players] 
    bad_request "missing mode" unless params[:mode] 
    bad_request "invalid mode" unless config[:game, :modes].include? params[:mode]
    
    # Work out which players will be in the game.
    player_names = params[:players].split ";"
    bad_request "username must be one of players" unless player_names.include? player.username

    players = Models::Player.includes username: player_names # Ensure the order is correct.
    bad_request "not all players exist" unless players.size == player_names.size
        
    # Check if the map exists.
    map = Models::Map.find(params[:map_id]) rescue nil
    bad_request "no such map" unless map
     
    # Create the game.
    game = Models::Game.create map: map, mode: params[:mode], players: players
    
    bad_request "failed to create game" unless game.persisted?
    
    (players - [player]).each do |opponent|
      opponent.send_mail "Challenge from #{player.username}", <<END
#{player.username} has challenged you to a game of #{config[:game, :name]}!

Players: #{game.players.map(&:username).join(", ")}
Map: #{game.map.name}
Mode: #{game.mode}
END
    end
   
    { 
      success: "game created",
      id: game.id,
    }.to_json  
  end
end
end