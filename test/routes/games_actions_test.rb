require_relative '../teststrap'
require_relative 'helpers/helper'

describe "/games route" do  
  before do
    create_players 
    @map = Robin::Models::Map.create! name: "My Map",
                data: "xyz", uploader: @player1  
  end
  after { clean_database }
  
  # GET /games/*/actions  
  describe "GET /games/*/actions" do
    before do
      actions = 3.times.map {|i| Robin::Models::Action.new data: i.to_s }
      @game = Robin::Models::Game.create! map: @map, mode: "pvp",
                           players: Robin::Models::Player.all, actions: actions     
    end
    
    should "return all the actions by default" do
      authorize 'fish', 'abcdefg'
      get "/games/#{@game.id}/actions"
      last_response.should.be.ok 
      last_response.content_type.should.equal JSON_TYPE
      body.should.equal ["0", "1", "2"]
    end
    
    should "return the all the actions from :from to the end" do
      authorize 'fish', 'abcdefg'
      get "/games/#{@game.id}/actions", from: 1
      last_response.should.be.ok 
      last_response.content_type.should.equal JSON_TYPE
      body.should.equal ["1", "2"]
    end
    
    should "return no actions if :from is after the end of the actions" do
      authorize 'fish', 'abcdefg'
      get "/games/#{@game.id}/actions", from: 3
      last_response.should.be.ok 
      last_response.content_type.should.equal JSON_TYPE
      body.should.equal []
    end
    
    should "fail is given a negative action number" do
      authorize 'fish', 'abcdefg'
      get "/games/#{@game.id}/actions", from: -4
      last_response.should.not.be.ok 
      last_response.content_type.should.equal JSON_TYPE
      body["error"].should.equal "bad action number"
    end
  end
  
  # POST /games/*/actions 
  describe "POST /games/*/actions" do
    before do     
      @game = Robin::Models::Game.create! map: @map, mode: "pvp", players: Robin::Models::Player.all
    end
    
    action_data.each_key do |key|    
      should "fail without #{key.inspect}" do 
        data = action_data.dup
        data.delete key        
        authorize 'fish', 'abcdefg'
        post "/games/#{@game.id}/actions", data
        
        last_response.should.not.be.ok
        last_response.content_type.should.equal JSON_TYPE 
        body.should.equal "error" => "missing #{key}"
        game = Robin::Models::Game.find @game.id   
        game.actions.count.should.equal 0  
        game.turn.should.equal 0
        game.complete?.should.equal false
      end 
    end
     
    should "fail if the game doesn't exist" do  
      authorize 'fish', 'abcdefg'    
      post "/games/#{game_id}/actions", action_data       
      
      last_response.should.not.be.ok
      last_response.content_type.should.equal JSON_TYPE 
      body.should.equal "error" => "game not found"
      game = Robin::Models::Game.find @game.id   
      game.actions.count.should.equal 0  
      game.turn.should.equal 0
      game.complete?.should.equal false
    end  
    
    should "fail if trying to submit an action in wrong turn" do 
      data = action_data.merge username: Robin::Models::Player.all[1].username
      authorize 'frog', 'abcdefg'
      post "/games/#{@game.id}/actions", data
      
      last_response.should.not.be.ok
      last_response.content_type.should.equal JSON_TYPE 
      body.should.equal "error" => "action sent out of sequence"
      game = Robin::Models::Game.find @game.id                   
      game.actions.count.should.equal 0  
      game.turn.should.equal 0
      game.complete?.should.equal false 
    end
    
    should "fail if trying to submit to a game you aren't in" do
      player3 = Robin::Models::Player.create! username: "cheeseman", email: "x@z.c",
                              password: "abcdefg"    
                              
      data = action_data.merge username: player3.username
      authorize 'cheeseman', 'abcdefg'
      post "/games/#{@game.id}/actions", data      
      
      last_response.should.not.be.ok
      last_response.content_type.should.equal JSON_TYPE 
      body.should.equal "error" => "player not in game"
      game = Robin::Models::Game.find @game.id                  
      game.actions.count.should.equal 0  
      game.turn.should.equal 0
      game.complete?.should.equal false 
    end
   
    should "succeed if the action sent by the expected player" do  
      authorize 'fish', 'abcdefg'    
      post "/games/#{@game.id}/actions", action_data    
      
      last_response.should.be.ok
      last_response.content_type.should.equal JSON_TYPE 
      body.should.equal "success" => "action accepted"
      game = Robin::Models::Game.find @game.id
      game.actions.count.should.equal 1
      game.turn.should.equal 0 
      game.complete?.should.equal false            
    end
    
    should "succeed and advance the turn if :end_turn sent" do
      any_instance_of Robin::Models::Player do |player|
        mock(player).send_mail "fish ended the turn", "fish has finished playing turn #1 on your Smash and Grab game."
      end
    
      authorize 'fish', 'abcdefg'
      post "/games/#{@game.id}/actions", action_data.merge(end_turn: true)
      
      last_response.should.be.ok
      last_response.content_type.should.equal JSON_TYPE 
      body.should.equal "success" => "turn advanced"
      game = Robin::Models::Game.find @game.id
      game.actions.count.should.equal 1
      game.turn.should.equal 1  
      game.complete?.should.equal false      
    end
    
    should "succeed and complete the game if :end_game sent" do
      any_instance_of Robin::Models::Player do |player|
        mock(player).send_mail "fish ended the turn", "fish has finished playing turn #1 on your Smash and Grab game, which has also completed the game."
      end
      
      authorize 'fish', 'abcdefg'
      post "/games/#{@game.id}/actions", action_data.merge(end_game: true)
      
      last_response.should.be.ok
      last_response.content_type.should.equal JSON_TYPE 
      body.should.equal "success" => "game completed"
      game = Robin::Models::Game.find @game.id
      game.actions.count.should.equal 1
      game.turn.should.equal 0
      game.complete?.should.equal true      
    end
  end
end