require_relative 'teststrap'

JSON_TYPE = "application/json;charset=utf-8"  
ID_PATTERN = /^[0-9a-f]{24}$/

def initial_game_data
  {
      scenario: "01_Giant_chicken",
      initial: { data: "cheese" }.to_json,
      players: "fish;frog",
      mode: "coop-baddies",
      username: "frog", 
      password: "abcdefg",
  }
end

def action
  { 
    do: "stuff",
  }
end

def action_data
  {
      username: "fish", 
      password: "abcdefg",
      data: action,
  }
end  

describe 'Smash and Grab server' do   
  before do
    def game_id; "1" * 24; end
    
    def player_names
      initial_game_data[:players].split(";")
    end    

    Player.create username: player_names[0], email: "x@y.c", password: "abcdefg"
    Player.create username: player_names[1], email: "z@y.c", password: "abcdefg"
  end
  
  after do
    Player.delete_all
    Game.delete_all # Action is a part of a game.
  end
  
  describe "get /" do
    should "give information about the server" do
      get '/'
      last_response.content_type.should.equal JSON_TYPE
      body.should.equal "name" => "Smash and Grab server", "version" => "0.0.1alpha"
    end
  end
  
  describe "get /games/*" do
    before do
      @game = Game.create! scenario: "x", initial: "meh", mode: "pvp",
                           players: Player.all
                           
      3.times {|i| @game.actions.create! data: i.to_s }
    end
    
    should "return the game and all actions by default" do
      get "/games/#{@game.id}"
      last_response.should.be.ok 
      last_response.content_type.should.equal JSON_TYPE
      body.should.equal( 
          "id" => @game.id.to_s,
          "scenario" => "x",
          "mode" => "pvp",
          "turn" => 0,
          "complete" => false,
          "initial" => "meh",          
          "actions" => ["0", "1", "2"],
      )
    end
  end
  
  describe "get /games/*/actions" do
    before do
      @game = Game.create! scenario: "x", initial: "meh", mode: "pvp",
                           players: Player.all
                           
      3.times {|i| @game.actions.create! data: i.to_s }
    end
    
    should "return the all the actions by default" do
      get "/games/#{@game.id}/actions"
      last_response.should.be.ok 
      last_response.content_type.should.equal JSON_TYPE
      body.should.equal ["0", "1", "2"]
    end
    
    should "return the all the actions from :from to the end" do
      get "/games/#{@game.id}/actions", from: 1
      last_response.should.be.ok 
      last_response.content_type.should.equal JSON_TYPE
      body.should.equal ["1", "2"]
    end
    
    should "return no actions if :from is after the end of the actions" do
      get "/games/#{@game.id}/actions", from: 3
      last_response.should.be.ok 
      last_response.content_type.should.equal JSON_TYPE
      body.should.equal []
    end
    
    should "fail is given a negative action number" do
      get "/games/#{@game.id}/actions", from: -4
      last_response.should.not.be.ok 
      last_response.content_type.should.equal JSON_TYPE
      body["error"].should.equal "bad action number"
    end
  end
  
  describe "get /players/*/games" do
    should "return a list of game ids" do
      game1 = Game.create! scenario: "x", initial: "s", mode: "pvp",
                       players: Player.all
      game2 = Game.create! scenario: "y", initial: "s", mode: "coop-baddies",
                       players: Player.all, turn: 2, complete: true
      game2.actions.create! data: action_data
      
      get "/players/fish/games"
       
      last_response.should.be.ok       
      last_response.content_type.should.equal JSON_TYPE 
      body.should.equal [
          {
              "id" => game1.id.to_s,
              "scenario" => "x",
              "mode" => "pvp",
              "turn" => 0,
              "complete" => false,              
          },
          {
              "id" => game2.id.to_s,
              "scenario" => "y",
              "mode" => "coop-baddies",
              "turn" => 2, 
              "complete" => true,      
          }
      ]
    end
  end
  
  describe "post /players" do
    should "create a new game and return a new id" do   
      post '/players', username: "cheese", password: "abcdefg", email: "fish@frog.com"
      
      last_response.should.be.ok
      last_response.content_type.should.equal JSON_TYPE    
      body.should.equal "success" => "player created"
      Player.count.should.equal 3
      Player.where(username: "cheese").first.email.should.equal "fish@frog.com"
    end
    
    should "fail if a player of that name already exists" do   
      post '/players', username: "frog", password: "abcdefg", email: "fish@frog.com"
      
      last_response.should.not.be.ok
      last_response.content_type.should.equal JSON_TYPE    
      body.should.equal "error" => "player already exists"
      Player.count.should.equal 2
    end 
  end
  
  describe "post /games/*" do   
    should "create a new game and return a new id" do   
      post '/games', initial_game_data
      
      last_response.should.be.ok
      last_response.content_type.should.equal JSON_TYPE 
      body.size.should.equal 2
      body['success'].should.equal "game created"      
      body['id'].should.match ID_PATTERN
      Game.find(body['id']).actions.count.should.equal 0
    end
    
    initial_game_data.each_key do |key|    
      should "fail without #{key.inspect}" do 
        data = initial_game_data.dup
        data.delete key        
        post '/games', data
        
        last_response.should.not.be.ok
        last_response.content_type.should.equal JSON_TYPE 
        body.should.equal "error" => "missing #{key}"
      end    
    end   
  end
  
  describe "post /games/*/actions" do
    before do
      @game = Game.create! scenario: "meh", initial: "meh", mode: "pvp",
                           players: Player.all
    end
    
    action_data.each_key do |key|    
      should "fail without #{key.inspect}" do 
        data = action_data.dup
        data.delete key        
        post "/games/#{@game.id}/actions", data
        
        last_response.should.not.be.ok
        last_response.content_type.should.equal JSON_TYPE 
        body.should.equal "error" => "missing #{key}"
        game = Game.find @game.id   
        game.actions.count.should.equal 0  
        game.turn.should.equal 0
        game.complete?.should.equal false
      end 
    end
     
    should "fail if the game doesn't exist" do     
      post "/games/#{game_id}/actions", action_data       
      
      last_response.should.not.be.ok
      last_response.content_type.should.equal JSON_TYPE 
      body.should.equal "error" => "game not found"
      game = Game.find @game.id   
      game.actions.count.should.equal 0  
      game.turn.should.equal 0
      game.complete?.should.equal false
    end  
    
    should "fail if trying to submit an action in wrong turn" do 
      data = action_data.merge username: Player.all[1].username
      post "/games/#{@game.id}/actions", data
      
      last_response.should.not.be.ok
      last_response.content_type.should.equal JSON_TYPE 
      body.should.equal "error" => "action sent out of sequence"
      game = Game.find @game.id                     
      game.actions.count.should.equal 0  
      game.turn.should.equal 0
      game.complete?.should.equal false 
    end
    
    should "fail if trying to submit to a game you aren't in" do
      player3 = Player.create! username: "cheeseman", email: "x@z.c",
                              password: "abcdefg"    
                              
      data = action_data.merge username: player3.username
      post "/games/#{@game.id}/actions", data      
      
      last_response.should.not.be.ok
      last_response.content_type.should.equal JSON_TYPE 
      body.should.equal "error" => "player not in game"
      game = Game.find @game.id                  
      game.actions.count.should.equal 0  
      game.turn.should.equal 0
      game.complete?.should.equal false 
    end
   
    should "succeed if the action sent by the expected player" do    
      post "/games/#{@game.id}/actions", action_data    
      
      last_response.should.be.ok
      last_response.content_type.should.equal JSON_TYPE 
      body.should.equal "success" => "action accepted"
      game = Game.find @game.id
      game.actions.count.should.equal 1
      game.turn.should.equal 0 
      game.complete?.should.equal false            
    end
    
    should "succeed and advance the turn if :end_turn sent" do     
      post "/games/#{@game.id}/actions", action_data.merge(end_turn: true)
      
      last_response.should.be.ok
      last_response.content_type.should.equal JSON_TYPE 
      body.should.equal "success" => "turn advanced"
      game = Game.find @game.id
      game.actions.count.should.equal 1
      game.turn.should.equal 1  
      game.complete?.should.equal false      
    end
    
    should "succeed and complete the game if :end_gane sent" do      
      post "/games/#{@game.id}/actions", action_data.merge(end_game: true)
      
      last_response.should.be.ok
      last_response.content_type.should.equal JSON_TYPE 
      body.should.equal "success" => "game completed"
      game = Game.find @game.id
      game.actions.count.should.equal 1
      game.turn.should.equal 0
      game.complete?.should.equal true      
    end
  end
end