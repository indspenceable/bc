window.Battlecon =
  Models: {}
  Collections: {}
  Views: {}
  Routers: {}
  initialize: ->
    this.GameStateCollection = new Battlecon.Collections.GameStates 5

$(document).ready ->
  Battlecon.initialize()
