require_relative 'teststrap'

JSON_TYPE = "application/json;charset=utf-8"  
ID_PATTERN = /^[0-9a-f]{24}$/

def initial_game_data
  {
     scenario: "01_Giant_chicken",
     initial: { data: "cheese" }.to_json,
     players: "fish;frog",
     mode: "coop-baddies"
  }
end

def actions
  {
     fish: "frog"
  }
end

def game_id; "1" * 24; end

class String
  # Make sure that we don't overwrite any live data.
  alias_method :old_tableize, :tableize
  def tableize
    "test_#{old_tableize}"
  end
end

describe 'Smash and Grab server' do 
  before do
    Player.delete_all
    Game.delete_all # Turn is a part of a game.
  end
  
  before do
    Player.delete_all
    Game.delete_all # Turn is a part of a game.  
    
    def create_players
      players = initial_game_data[:players].split(";")
      Player.new(name: players[0], email: "", password: "x").insert
      Player.new(name: players[1], email: "", password: "x").insert
    end
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
      mock(Player).where(name: "ted").mock!.first.mock!.games.returns ["frog"]
      
      get "/players/ted/games"
           
      last_response.content_type.should.equal JSON_TYPE 
      body.size.should.equal 1
      body['games'].should.equal ["frog"]
    end
  end
  
  describe "post /games/*" do
    should "create a new game and return a new id" do
      create_players
    
      post '/games', initial_game_data
      
      last_response.content_type.should.equal JSON_TYPE 
      body.size.should.equal 5    
      body['id'].should.match /^[0-9a-f]{24}$/
      body['scenario'].should.equal initial_game_data[:scenario]
      body['players'].should.equal players
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
      post "/games/#{game_id}/4", actions: actions, name: "fish" 
      
      last_response.should.not.be.ok
      last_response.content_type.should.equal JSON_TYPE 
      body.should.equal "error" => "game not found",
                        "game_id" => game_id
    end  
    
    should "fail if trying to submit a turn out of sequence" do     
      post "/games/#{game_id}/4", actions: actions, name: "frog"
      
      last_response.should.not.be.ok
      last_response.content_type.should.equal JSON_TYPE 
      body.should.equal "error" => "turn sent out of sequence",
                        "game_id" => game_id, "turn" => 4
    end
   
    should "succeed if the turn is the one expected" do
      post "/games/#{game_id}/4", actions: actions, name: "frog"
      
      last_response.should.not.ok
      last_response.content_type.should.equal JSON_TYPE 
      body.should.equal "success" => "turn accepted"
    end
  end
end