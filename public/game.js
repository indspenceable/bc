var init = function(player_id, game_id, character_names) {
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
    $('.my-hand').removeClass('select_me')
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
      $('.my-hand').addClass('select-me')
    } else if (question) {
      // Use Freeform Input
      $('.free-form').show()
      $('.answer-links').hide()
    }
  }
  var setUI = function(data) {
    // We should short circuit unless there have been updates.
    $('.board .space').empty()
    var requiredInput = data['requiredInput']
    $('.current-question').html(pretty(requiredInput))
      setup_inputs(requiredInput)
    var gameState = data['gameState']
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
    console.log(base,style)
    // This needs to fill in the appropriate image.
    if (base && style) {
      sendPair()
    }
  }
  var style
  var setStyle = function(styleName) {
    style=styleName
    console.log(base,style)
    // This needs to fill in the appropriate image.
    if (base && style) {
      sendPair()
    }
  }
  var sendPair = function() {
    console.log("c")
    $('.free-form input').val(style + "_" + base)
    base = undefined
    style = undefined
    $('.free-form').submit()
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
    $('.my-cards').on('click', '.select-me .bases .card', function() {
      console.log("a")
      setBase($(this).text())
    })
    $('.my-cards').on('click', '.select-me .styles .card', function() {
      console.log("b")
      setStyle($(this).text())
    })
  })
}

var Game = {init: init}
