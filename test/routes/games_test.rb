require_relative '../teststrap'
require_relative 'helpers/helper'

describe "/games route" do  
  before { create_players } 
  after { clean_database }
  
  # GET /games/*
  describe "GET /games/*" do
    before do
      actions = 3.times.map {|i| Action.new data: i.to_s }
      @game = Game.create! scenario: "x", initial: "meh", mode: "pvp",
                           players: Player.all, actions: actions    
    end
    
    should "return the game and all actions by default" do
      authorize 'fish', 'abcdefg'
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
  
  # POST /games
  describe "POST /games" do   
    should "create a new game and return a new id" do   
      authorize 'fish', 'abcdefg'
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
        authorize 'fish', 'abcdefg'
        data = initial_game_data.dup
        data.delete key        
        post '/games', data
        
        last_response.should.not.be.ok
        last_response.content_type.should.equal JSON_TYPE 
        body.should.equal "error" => "missing #{key}"
      end    
    end   
  end
end