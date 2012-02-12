def initial_game_data
  {
      players: "fish;frog",
      mode: "coop-baddies",
  }
end

def action
  { 
    do: "stuff",
  }
end

def action_data
  {
      data: action,
  }
end  

def game_id; "1" * 24; end
def player_names; initial_game_data[:players].split(";"); end   

def create_players
    @player1 = Robin::Models::Player.create username: player_names[0], email: "x@y.c", password: "abcdefg"
    @player2 = Robin::Models::Player.create username: player_names[1], email: "z@y.c", password: "abcdefg"
end