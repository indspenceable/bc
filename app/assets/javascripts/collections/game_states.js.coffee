class Battlecon.Collections.GameStates extends Backbone.Collection
  constructor: (@gameId) ->
    this.url = "/games/#{@gameId}.json"
    this.fetch

  model: Battlecon.Models.GameState
