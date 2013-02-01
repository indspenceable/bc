var init = function(player_id, game_id, character_names) {
  var pretty = function(str) {
    return ({
    }[str] || str)
  }
  var options_for_question = function(question) {
    if (question == "select_character") {
      return character_names
    } else return false;
  }
  var setup_inputs = function(question) {
    $('.freeForm').hide()
    $('.answerLinks').hide()
    $('.myhand').removeClass('select_me')
    var opts = options_for_question(question)
    if (opts) {
      $('.freeForm').hide()
      var $answerLinks = $('.answerLinks')
      $answerLinks.empty()
      for (var i = 0; i < opts.length; i += 1) {
        var str = '<a href="#" onclick="return(false);" choice="' + opts[i] + '"> ' + pretty(opts[i]) + " </a>"
        $answerLinks.append(str)
      }
      $answerLinks.show()
    } else if (question == "select_attack_pairs") {
      $('.freeForm').hide()
      $('.answerLinks').hide()
      $('.myHand').addClass('selectMe')
    } else if (question) {
      // Use Freeform Input
      $('.freeForm').show()
      $('.answerLinks').hide()
    }
  }
  var setUI = function(data) {
    // We should short circuit unless there have been updates.
    $('.board .space').empty()
    var requiredInput = data['requiredInput']
    $('.currentQuestion').html(requiredInput)
      setup_inputs(requiredInput)
    var gameState = data['gameState']
    $('.eventLog').html(gameState['events'].join("\n"))
  }
  var ping = function() {
    $.get('/ping/' + game_id + '/', {
      'player_id': player_id
    }, function(data) {
      setUI(data)
      setTimeout(ping, 1000)
    }, 'json')
  }
  var base
  var setBase = function(baseName) {
    base = baseName
    console.log(base,style)
    if (base && style) {
      sendPair()
    }
  }
  var style
  var setStyle = function(styleName) {
    style=styleName
    console.log(base,style)
    if (base && style) {
      sendPair()
    }
  }
  var sendPair = function() {
    console.log("c")
    $('.freeForm input').val(style + "_" + base)
    base = undefined
    style = undefined
    $('.freeForm').submit()
  }
  $(function() {
    $('input').closest('form').on('submit', function() {
      var $input = $(this).find('input')
      $.post('/games/' + game_id + '/', {
        'player_id': player_id,
        'action': $input.val()
      }, function(data) {
        setUI(data)
      }, 'json')
      return false;
    })
    $('.answerLinks').on('click', 'a', function() {
      $('.freeForm input').val($(this).attr('choice'))
      $('.freeForm').submit()
    })
    ping()
    $('.myCards').on('click', '.selectMe .bases .card', function() {
      console.log("a")
      setBase($(this).text())
    })
    $('.myCards').on('click', '.selectMe .styles .card', function() {
      console.log("b")
      setStyle($(this).text())
    })
  })
}

var Game = {init: init}
