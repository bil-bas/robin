require_relative '../teststrap'
require_relative 'helpers/helper'

describe "/games route" do  
  before do
    create_players
    @map = Robin::Models::Map.create! name: "My Map", data: "xyz", 
                       uploader: @player1
  end
  after { clean_database }
  
  # GET /games/*
  describe "GET /games/*" do
    before do
      actions = 3.times.map {|i| Robin::Models::Action.new data: i.to_s }

      @game = Robin::Models::Game.create! map: @map, mode: "pvp",
                           players: Robin::Models::Player.all, actions: actions    
    end
    
    should "return the game and all actions by default" do
      authorize 'fish', 'abcdefg'
      get "/games/#{@game.id}"
      last_response.should.be.ok 
      last_response.content_type.should.equal JSON_TYPE
      body.should.equal( 
          "game_id" => @game.id.to_s,
          "map_id" => @map.id.to_s,
          "mode" => "pvp",
          "turn" => 0,
          "complete" => false,
          "actions" => ["0", "1", "2"]
      )
    end
  end
  
  # POST /games
  describe "POST /games" do   
    should "create a new game and return a new id" do  
      any_instance_of Robin::Models::Player do |player|
        mock(player).send_mail "Challenge from fish", <<END
fish has challenged you to a game of Smash and Grab!

Players: fish, frog
Map: My Map
Mode: coop-baddies
END
      end
      
      authorize 'fish', 'abcdefg'
      post '/games', initial_game_data.merge(map_id: @map.id)
      
      last_response.should.be.ok
      last_response.content_type.should.equal JSON_TYPE 
      body.size.should.equal 2
      body['success'].should.equal "game created"      
      body['id'].should.match ID_PATTERN
      Robin::Models::Game.find(body['id']).actions.count.should.equal 0
    end
    
    initial_game_data.each_key do |key|    
      should "fail without #{key.inspect}" do 
        authorize 'fish', 'abcdefg'
        data = initial_game_data.dup
        data.delete key        
        post '/games', data.merge(map_id: @map.id)
        
        last_response.should.not.be.ok
        last_response.content_type.should.equal JSON_TYPE 
        body.should.equal "error" => "missing #{key}"
      end    
    end   
  end
end