var init = function(player_id, game_id, character_names) {
  var cachedEventCount = undefined;
  var cachedQuestion = undefined;
  var pretty = function(str) {
    return ({
      'select_character': "Please select a character:"
    }[str] || str)
  }
  var options_for_question = function(question) {
    if (question == "select_character") {
      return character_names
    } else return false;
  }
  var setup_inputs = function(question) {
    $('.free-form').hide()
    $('.answer-links').hide()
    $('.p' + player_id + '-hand').find('.bases, .styles').removeClass('select-me')
    $('.current-attack-pair').hide()

    var opts = options_for_question(question)
    if (opts) {
      $('.free-form').hide()
      var $answerLinks = $('.answer-links')
      $answerLinks.empty()
      for (var i = 0; i < opts.length; i += 1) {
        var str = '<a href="#" onclick="return(false);" choice="' + opts[i] + '"> ' + pretty(opts[i]) + " </a>"
        $answerLinks.append(str)
      }
      $answerLinks.show()
    } else if (question == "select_attack_pairs") {
      $('.free-form').hide()
      $('.answer-links').hide()
      $('.p' + player_id + '-hand').find('.bases, .styles').addClass('select-me')
      $('.current-attack-pair').empty().show()
    } else if (question) {
      // Use Freeform Input
      $('.free-form').show()
      $('.answer-links').hide()
    }
  }
  var setUI = function(data) {
    // short circuit unless more events have happened, or
    // there is a new question.
    if (data['gameState']['events'].length == cachedEventCount &&
      data['requiredInput'] == cachedQuestion) {
      return;
    }
    cachedEventCount = data['gameState']['events'].length;
    cachedQuestion = data['requiredInput'];

    // Do everything required for this question.
    var requiredInput = data['requiredInput']
    $('.current-question').text(pretty(requiredInput))
    setup_inputs(requiredInput)

    // Updates related to the gamestate
    var gameState = data['gameState']
    if (!gameState.players) { return }
    // clear the board
    console.log(gameState)
    $('.board .space').empty()
    $('.space-' + gameState.players[0].location).text('0')
    $('.space-' + gameState.players[1].location).text('1')

    // show the players hands

    for (var pn = 0; pn <= 1; pn++) {
      console.log("pn is ", pn)
      var $bases = $('.p' + pn + '-hand .bases').empty()
      var $styles = $('.p' + pn + '-hand .styles').empty()
      for (var index in gameState.players[pn].bases) {
        $('<div/>').addClass('card').text(gameState.players[pn].bases[index]).appendTo($bases)
      }
      for (var index in gameState.players[pn].styles) {
        $('<div/>').addClass('card').text(gameState.players[pn].styles[index]).appendTo($styles)
      }
    }

    $('.eventLog').html(gameState['events'].join("<br/>"))
  }
  var ping = function() {
    $.get('/ping/' + game_id + '/', {
      'player_id': player_id
    }, function(data) {
      setUI(data)
      setTimeout(ping, 1000)
    }, 'json')
  }

  // This is for select_attack_pairs choice.
  // ---------------------------------------
  var base
  var setBase = function(baseName) {
    base = baseName
    // This needs to fill in the appropriate image.
    setPair()
  }
  var style
  var setStyle = function(styleName) {
    style=styleName
    // This needs to fill in the appropriate image.
    setPair()
  }
  var setPair = function() {
    var cap = $('.current-attack-pair')
    cap.text(
      (style ? style : "---") + " " + (base ? base : "---")
    )

    if (base && style) {
      $('<div/>').addClass('click-me').text('submit').click(function() {
        $('.free-form input').val(style + "_" + base)
        base = undefined
        style = undefined
        $('.free-form').submit()
      }).appendTo(cap)
    }
  }



  // ---------------------------------------

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
    $('.answer-links').on('click', 'a', function() {
      $('.free-form input').val($(this).attr('choice'))
      $('.free-form').submit()
    })
    ping()
    $('.p' + player_id + '-cards').on('click', '.select-me.bases .card', function() {
      setBase($(this).text())
    })
    $('.p' + player_id + '-cards').on('click', '.select-me.styles .card', function() {
      setStyle($(this).text())
    })
  })
}

var Game = {init: init}
