def initial_game_data
  {
      scenario: "01_Giant_chicken",
      initial: { data: "cheese" }.to_json,
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
    Player.create username: player_names[0], email: "x@y.c", password: "abcdefg"
    Player.create username: player_names[1], email: "z@y.c", password: "abcdefg"
end

def clean_database
  Player.delete_all
  Game.delete_all # Action is a part of a game.
end 