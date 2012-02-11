require_relative 'teststrap'
require_relative 'routes/helpers/helper'

describe '/ routes' do
  before { create_players } 
  after { clean_database }
  
  describe "GET /" do
    should "give information about the server" do
      get '/'
      last_response.content_type.should.equal JSON_TYPE
      body.should.equal "name" => "Smash and Grab server", "version" => "0.0.1alpha"
    end
  end
  
  describe "errors" do
    should "handle page not found (404)" do
      get '/blehblehbleh'
      last_response.should.not.be.ok
      last_response.status.should.equal 404
      last_response.content_type.should.equal JSON_TYPE
      body.should.equal "error" => "not found"
    end
    
    should "handle access denied (401)" do
      get '/maps'
      last_response.should.not.be.ok
      last_response.status.should.equal 401
      last_response.content_type.should.equal JSON_TYPE
      body.should.equal "error" => "access denied"
    end
    
     should "handle server error (500)" do
       # Need to check in production environment, otherwise it 
       # will just  exceptions for you.
       app.set :environment, :production
             
       mock(Player).authenticate('x', 'y') { raise "Oh bugger!" }
       authorize 'x', 'y'    
       get '/maps'
       
       app.set :environment, :test
       
       last_response.should.not.be.ok
       last_response.status.should.equal 500
       last_response.content_type.should.equal JSON_TYPE
       body.should.equal "error" => "server error"
    end
  end
end