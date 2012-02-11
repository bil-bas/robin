Smash and Grab Server
=====================

Central server for the game [Smash and Grab](http://spooner.github.com/games/smash_and_grab)

* Author: Spooner (Bil Bas) bil.bagpuss@gmail.com
* License: [MIT](http://www.opensource.org/licenses/mit-license.php)
* Website: [Smash and Grab](http://spooner.github.com/games/smash_and_grab)
* Github: [Spooner/smash_and_grab_server](https://github.com/Spooner/smash_and_grab_server)

RESTful Routes
--------------

* `GET /`                       
  - Server information


### Games

* `GET  /games`                
    - Retrieve list of games.

* `GET  /games/<game-id>`       
    - Download a particular game.

* `POST /games`                 
    - Create a new game.

* `GET  /games/<game-id>/actions`
    - Retreive a list of actions so far.

* `POST /games/<game-id>/actions`
    - Submit an action (or turn).


### Maps

* `GET  /maps`              
    - Get list of maps.

* `GET  /maps/<map-id>`       
    - Retreive map data.

* `POST /maps`
    - Upload a new map.

### Players

* `GET  /players`            
    - Get a list of players.

* `POST /players`             
    - Create a new player.
    
* `GET  /players/<player-name>`            
    - Get information about a player.
    
* `GET  /players/<player-name>/games`
    - List of games the player has played or is playing.
    
* `GET  /players/<player-name>/maps`
    - List of maps the player has uploaded.



