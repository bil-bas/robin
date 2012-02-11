require_relative '../teststrap'
require_relative 'helpers/helper'

describe "/players route" do
  before do
    create_players
    @map = Map.create! name: "My Map", data: "xyz", 
                       uploader: @player1
  end 
  
  after { clean_database }
  
  describe "GET /players/*/games" do
    should "return a list of game summaries" do
      game1 = Game.create! map: @map, mode: "pvp",
                           players: Player.all
      game2 = Game.create! map: @map, mode: "coop-baddies",
             players: Player.all, turn: 2, complete: true,
             actions: [Action.new(data: action_data)]
      
      authorize 'fish', 'abcdefg'
      get "/players/fish/games"
       
      last_response.should.be.ok       
      last_response.content_type.should.equal JSON_TYPE 
      body.should.equal [
          {
              "game_id" => game1.id.to_s,
              "map_id" => @map.id.to_s,
              "mode" => "pvp",
              "turn" => 0,
              "complete" => false,              
          },
          {
              "game_id" => game2.id.to_s,
              "map_id" => @map.id.to_s,
              "mode" => "coop-baddies",
              "turn" => 2, 
              "complete" => true,      
          }
      ]
    end
  end
end