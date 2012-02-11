class TurnServer < Sinatra::Base 
  # List maps.
  get "/maps" do
    player = validate_for_access :any_player
    
    {
        maps: Map.all.map(&:id),
    }.to_json
  end
  
  # Download a map.
  get %r{/maps/#{ID_PATTERN}} do |game_id|
    player = validate_for_access :any_player
    
    map = Map.find(game_id) rescue nil
    bad_request "no such map" unless map
    
    {
        map: map.data,
    }.to_json
  end
  
  # Upload a map.
  post "/maps" do
    player = validate_for_access :any_player    
    
    bad_request "missing name" unless params[:name]
    bad_request "missing data" unless params[:data]
            
    map = Map.create name: params[:name], data: params[:data], 
                     uploader: player
                      
    bad_request "map already uploaded" unless map.persisted?
    
    {
        success: "map uploaded",
        id: map.id,
    }.to_json
  end 
end
  