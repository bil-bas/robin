require_relative '../teststrap'
require_relative 'helpers/helper'

describe "/players route" do
  before do
    create_players
    
    @map1 = Map.create! name: "My Map", data: "xyz", 
                        uploader: @player1
                       
    @map2 = Map.create! name: "My other map", data: "abc", 
                        uploader: @player2
  end
  
  after { clean_database }
  
  describe "GET /maps" do
    should "get list of maps" do   
      authorize 'fish', 'abcdefg'
      get '/maps'
      
      last_response.should.be.ok
      last_response.content_type.should.equal JSON_TYPE  
      body.should.equal "maps" => [@map1.id.to_s, @map2.id.to_s]
      Map.count.should.equal 2
    end 
  end
  
  describe "POST /maps" do
    should "create a new game and return a new id" do   
      authorize 'fish', 'abcdefg'
      post '/maps', data: "cheese", name: "My even better map"
      
      last_response.should.be.ok
      last_response.content_type.should.equal JSON_TYPE       
      body.should.equal "success" => "map uploaded",
                        "id" => Map.last.id.to_s
      Map.count.should.equal 3
    end
    
    should "fail if the map has already been uploaded" do
      authorize 'fish', 'abcdefg'
      post '/maps', data: @map1.data, name: @map1.name
      
      last_response.should.not.be.ok
      last_response.content_type.should.equal JSON_TYPE    
      body.should.equal "error" => "map already uploaded"
      Map.count.should.equal 2
    end 
  end
end