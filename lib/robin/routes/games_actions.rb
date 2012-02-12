module Robin
class Server < Sinatra::Base
  # Get actions for a game. Defaults to all actions, but can define :from
  get %r{/games/#{ID_PATTERN}/actions} do |game_id|
    validate_for_access :any_player
    
    from = params[:from].to_i # May be nil, which becomes 0
   
    game = Models::Game.find(game_id) rescue nil 
    bad_request "game not found" unless game
    
    bad_request "bad action number" if from < 0
    
    game.actions[from..-1].map(&:data).to_json
  end

  # Add a new action to a game.
  post %r{/games/#{ID_PATTERN}/actions} do |game_id|
    player = validate_for_access :any_player
    
    bad_request "missing data" unless params[:data] 
   
    # Check if the game exists.
    game = Models::Game.find(game_id) rescue nil
    bad_request "game not found" unless game

    # Check if the player validated is actually one of the players.
    bad_request "player not in game" unless game.players.include? player

    # Ignore actions after the game is finished.
    bad_request "game already complete" if game.complete?
    
    # Ignore actions sent, unless by the currently active player. 
    bad_request "action sent out of sequence" unless player == game.current_player
    
    action = game.actions.create data: params[:data]
    bad_request "failed to create action" unless action.persisted?
    
    # Work out the message to return to the player.
    message = if params[:end_game]
                # Close off the game if the action ended the game.
                game.complete = true
                game.update   
                "game completed"
              elsif params[:end_turn]   
                # Advance to new turn if the action ended the turn. 
                game.turn += 1
                game.update
                "turn advanced"
              else 
                "action accepted"
              end
              
    # Send an email update.
    if params[:end_turn] or params[:end_game]
      turn_number = (game.turn.fdiv game.players.size).floor + 1
      (game.players - [player]).each do |opponent|
        opponent.send_mail "#{player.username} ended the turn",
              "#{player.username} has finished playing turn ##{turn_number} on your #{config[:game, :name]} game#{params[:end_game] ? ", which has also completed the game" : ""}."
      end
    end
    
    { success: message }.to_json 
  end
end
end



