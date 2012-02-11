require_relative '../teststrap'
require_relative 'helpers/helper'

describe "/games route" do  
  before { create_players } 
  after { clean_database }
  
  # GET /games/*/actions  
  describe "GET /games/*/actions" do
    before do
      actions = 3.times.map {|i| Action.new data: i.to_s }
      @game = Game.create! scenario: "xxy", initial: "meh", mode: "pvp",
                           players: Player.all, actions: actions     
    end
    
    should "return all the actions by default" do
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
  
  # POST /games/*/actions 
  describe "POST /games/*/actions" do
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