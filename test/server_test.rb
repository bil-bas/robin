require_relative 'teststrap'

JSON_TYPE = "application/json;charset=utf-8"  
ID_PATTERN = /^[0-9a-f]{24}$/

describe 'Smash and Grab server' do   
  before do   
    def create_players
      players = initial_game_data[:players].split(";")
      Player.new(name: players[0], email: "x@y", password: "x").insert
      Player.new(name: players[1], email: "z@y", password: "x").insert
      players
    end
    
    def initial_game_data
      {
          scenario: "01_Giant_chicken",
          initial: { data: "cheese" }.to_json,
          players: "fish;frog",
          mode: "coop-baddies"
      }
    end

    def actions
      [
          { do: "stuff"},
          { do: "more stuff"},
      ]
    end

    def game_id; "1" * 24; end
  end
  
  after do
    Player.delete_all
    Game.delete_all # Turn is a part of a game.
  end
  
  describe "get /" do
    should "give information about the server" do
      get '/'
      last_response.content_type.should.equal JSON_TYPE
      body.should.equal "name" => "Smash and Grab", "version" => "0.0.1"
    end
  end
  
  describe "get /players/*/games" do
    should "return a list of game ids" do
      create_players
      game1 = Game.new(scenario: "x", mode: "pvp", players: Player.all).insert
      game2 = Game.new(scenario: "y", mode: "coop-baddies", players: Player.all).insert
      game2.turns.create actions: actions
      
      get "/players/fish/games"
           
      last_response.content_type.should.equal JSON_TYPE 
      body['games'].should.equal [
          {
              "id" => game1.id.to_s,
              "scenario" => "x",
              "mode" => "pvp",
              "turns" => 0, 
          },
          {
              "id" => game2.id.to_s,
              "scenario" => "y",
              "mode" => "coop-baddies",
              "turns" => 1, 
          }
      ]
    end
  end
  
  describe "post /players" do
  
  end
  
  describe "post /games/*" do
    should "create a new game and return a new id" do
      player_names = create_players
    
      post '/games', initial_game_data
      
      last_response.content_type.should.equal JSON_TYPE 
      body.size.should.equal 5    
      body['id'].should.match ID_PATTERN
      body['scenario'].should.equal initial_game_data[:scenario]
      body['players'].should.equal player_names
      body['mode'].should.equal initial_game_data[:mode]
      DateTime.parse(body['started_at']).to_f.should.be.close Time.now.to_f - 1, 2
    end
    
    initial_game_data.each_key do |key|    
      should "fail without #{key.inspect}" do 
        data = initial_game_data.dup
        data.delete key        
        post '/games', data
        last_response.content_type.should.equal JSON_TYPE 
        last_response.should.not.be.ok
      end    
    end   
  end
  
  describe "post /games/*/*" do  
    should "fail without actions" do
      post "/games/#{game_id}/4", name: "frog"
      
      last_response.should.not.be.ok
      last_response.content_type.should.equal JSON_TYPE 
      body.should.equal "error" => "missing actions"
    end 
    
    should "fail without name" do
      post "/games/#{game_id}/4", actions: actions
      
      last_response.should.not.be.ok
      last_response.content_type.should.equal JSON_TYPE 
      body.should.equal "error" => "missing name"
    end 
     
    should "fail if the game doesn't exist" do     
      post "/games/#{game_id}/2", actions: actions, name: "fish" 
      
      last_response.should.not.be.ok
      last_response.content_type.should.equal JSON_TYPE 
      body.should.equal "error" => "game not found",
                        "game_id" => game_id
    end  
    
    should "fail if trying to submit a turn too early" do       
      create_players
      game = Game.new(scenario: "meh", initial: "meh", mode: "pvp", players: Player.all)
      game.insert
      
      post "/games/#{game.id}/2", actions: actions, name: "frog"
      
      last_response.should.not.be.ok
      last_response.content_type.should.equal JSON_TYPE 
      body.should.equal "error" => "turn sent out of sequence",
                        "game_id" => game.id.to_s, "turn" => 2
                        
      game.turns.count.should.equal 0
    end
    
    should "fail if trying to submit a turn too late" do 
      create_players    
      game = Game.new(scenario: "meh", initial: "meh", mode: "pvp", players: Player.all)
      game.turns.create actions: actions
      game.turns.create actions: actions
      game.insert
      
      post "/games/#{game.id}/2", actions: actions, name: "frog"
      
      last_response.should.not.be.ok
      last_response.content_type.should.equal JSON_TYPE 
      body.should.equal "error" => "turn sent out of sequence",
                        "game_id" => game.id.to_s, "turn" => 2
                        
      game.turns.count.should.equal 2
    end
   
    should "succeed if the turn is the one expected" do
      create_players
      game = Game.new(scenario: "meh", initial: "meh", mode: "pvp", players: Player.all)
      game.turns.create actions: actions
      game.insert
      
      post "/games/#{game.id}/2", actions: actions, name: "frog"
      
      last_response.should.be.ok
      last_response.content_type.should.equal JSON_TYPE 
      body.should.equal "success" => "turn accepted"
      game.turns.count.should.equal 2      
    end
  end
end