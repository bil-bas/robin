class TurnServer < Sinatra::Base
  # Create a player
  post '/players' do
    bad_request "missing username" unless params[:username] 
    bad_request "missing password" unless params[:password] 
    bad_request "missing email" unless params[:email]
    
    bad_request "player already exists" if Player.where(username: params[:username]).first
    
    Player.create! username: params[:username], email: params[:email],
                   password: params[:password]
    
    { 
        "success" => "player created",
    }.to_json
  end    
end

