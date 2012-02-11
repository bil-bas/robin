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
end