require_relative '../teststrap'
require_relative 'helpers/helper'

describe "/players route" do
  before { create_players } 
  after { clean_database }
  
  describe "GET /players/*/games" do
    should "return a list of game summaries" do
      game1 = Game.create! scenario: "x", initial: "s", mode: "pvp",
                       players: Player.all
      game2 = Game.create! scenario: "y", initial: "s", mode: "coop-baddies",
                       players: Player.all, turn: 2, complete: true,
                       actions: [Action.new(data: action_data)]
      
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
end