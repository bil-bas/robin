class TurnServer < Sinatra::Base
  # GET/POST /games and /games/*
  
  # Get a complete game, includeing all actions.
  get %r{/games/#{ID_PATTERN}} do |game_id|
    validate_for_access :any_player
    
    game = Game.find(game_id) rescue nil
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
    bad_request "invalid mode" unless SmashAndGrab::VALID_GAME_MODES.include? params[:mode]
    
    # Work out which players will be in the game.
    player_names = params[:players].split ";"
    bad_request "username must be one of players" unless player_names.include? player.username

    players = Player.includes username: player_names # Ensure the order is correct.
    bad_request "not all players exist" unless players.size == player_names.size
        
    # Check if the map exists.
    map = Map.find(params[:map_id]) rescue nil
    bad_request "no such map" unless map
     
    # Create the game.
    game = Game.create map: map, mode: params[:mode], players: players
    
    bad_request "failed to create game" unless game.persisted?
   
    { 
      success: "game created",
      id: game.id,
    }.to_json  
  end
end



