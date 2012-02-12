module Robin
class Server < Sinatra::Base
  # Create a player
  post '/players' do   
    bad_request "missing email" unless params[:email]
       
    player = Models::Player.create username: params[:username],
        email: params[:email], password: params[:password]
                   
    bad_request "player already exists" unless player.persisted?
    
    { 
        "success" => "player created",
    }.to_json
  end    
end
end

