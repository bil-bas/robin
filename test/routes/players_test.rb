require_relative '../teststrap'
require_relative 'helpers/helper'

describe "/players route" do
  before { create_players } 
  after { clean_database }
  
  describe "POST /players" do
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
end