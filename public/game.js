function capitaliseFirstLetter(string)
{
    return string.charAt(0).toUpperCase() + string.slice(1);
}

var init = function(player_id, game_id, character_names) {
  var cachedEventCount = undefined;
  var cachedQuestion = undefined;
  var $root = function(pn) {
    return (pn == player_id ? $(".js-mine") : $('.js-theirs'))
  }

  var makeCard = function(range, power, priority, _data) {
    data = _data || {}
    data.range = "" + range
    data.power = "" + power
    data.priority = "" + priority
    return data
  }
  var cardDefinitions = {
    dash: makeCard("N/A", "N/A", 9, {"After Activating": "Move 1, 2, or 3 spaces. If you switch sides with an opponent, they cannot hit you this turn."}),
    grasp: makeCard(1, 2, 5, {"On Hit": "Move opponent 1 space."}),
    drive: makeCard(1, 3, 4, {"Before Activating": "Advance 1 or 2 spaces."}),
    strike: makeCard(1, 4, 3, {"Stun Guard": "5"}),
    shot: makeCard("1~4", 3, 2, {"Stun Guard": "2"}),
    burst: makeCard("2~3", 3, 1, {"Start of Beat": "Retreat 1 or 2 spaces."}),

    palmstrike: makeCard(1, 2, 5, {"Start of Beat": "Advance 1 space.", "On Damage": "Recover an elemental token of your choice."}),
    geomantic: makeCard(0, 1, 0, {"Start of Beat": "You may ante another token for this beat."}),
    focused: makeCard(0, 1, 0, {"On Hit": "Recover an elemental token of your choice."}),
    trance: makeCard("0~1", 0, 0, {"Start of Beat": "Return all anted tokens to your pool. You don't get their effects this turn.", "End of Beat": "Recover an elemental token of your choice."}),
    sweeping: makeCard(0, -1, 3, {"passive": "If hikaru gets hit this turn, he takes 2 additional damage."}),
    advancing: makeCard(0, 1, 1, {"Start of beat": "Advance 1 space. If this causes you to switch sides with an opponent, you get +1 power this beat."})

  }
  var loadCard = function(styleOrBase, cardName, $pair) {
    var $card = $pair.find('.' + styleOrBase)
    $card.find('.name').text(capitaliseFirstLetter(cardName))
    $card.find('.effects').empty()
    var card = cardDefinitions[cardName]
    for (var attr in card) {
      if (attr == 'range') {
        $card.find('.range').text(card.range)
      } else if (attr == "power") {
        $card.find('.power').text(card.power)
      } else if (attr == "priority") {
        $card.find('.priority').text(card.priority)
      } else {
        $card.find('.effects').append($('<p/>').html("<b>" + attr + ":</b> " + card[attr]))
      }
    }
  }

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

  var chooseCharacter = function() {
    $('.js-in-game').hide()
    $('.js-choose-character').show()
  }
  var selectAttackPair = function() {
    $root(player_id).find('.js-bases, .js-styles').addClass("select-me")
  }
  var freeFormInput = function() {
    $('.free-form').show()
  }
  var setAnswers = function(question) {
    var $answers = $('.js-answers')
    $answers.empty()
    var matches = question.match(/<[^>]*>/g)
    for (var i in matches) {
      var currentMatch = matches[i].substring(1, matches[i].length-1)
      $('<a/>').addClass('btn').text(currentMatch).appendTo($answers)
    }
    $answers.show()
  }

  var resetInputs = function() {
    $('.js-bases, .js-styles, .js-tokens').removeClass("select-me")
    $('.free-form').hide()
    $('.js-answers').hide()
  }

  var setup_inputs = function(question) {
    resetInputs();
    console.log("question is: ", question)
    if (/^attack_pair/.test(question)) {
      selectAttackPair()
    } else if (question == "select_character") {
      chooseCharacter()
    } else if (question == "ante") {
      freeFormInput()
    } else if (/^select_from:/.test(question)) {
      setAnswers(question)
    }
    return;
  }




  var displayBoard = function(p0, p1) {
    $('.board').find('.space').empty()
    $('.board').find('.s' + p0).text("0")
    $('.board').find('.s' + p1).text("1")
  }
  var fillHand = function(pn, bases, styles) {
    var $bases = $root(pn).find('.js-bases').empty()
    var $styles = $root(pn).find('.js-styles').empty()
    for (var index in bases) {
      $('<div/>').addClass('card').text(bases[index]).appendTo($bases)
    }
    for (var index in styles) {
      $('<div/>').addClass('card').text(styles[index]).appendTo($styles)
    }
  }

  var setUI = function(data) {
    // short circuit unless more events have happened, or
    // there is a new question.
    if (data['gameState']['events'].length == cachedEventCount &&
      data['requiredInput'] == cachedQuestion) {
      return;
    }
    // Set the cache so we'll shortcircuit next time.
    cachedEventCount = data['gameState']['events'].length;
    cachedQuestion = data['requiredInput'];

    $('.js-loading').hide()
    $('.js-in-game').show()

    // Do everything required for this question.
    var requiredInput = data['requiredInput']
    setup_inputs(requiredInput)

    // Updates related to the gamestate
    var gameState = data['gameState']
    if (!gameState.players) { return }
    // Display the board
    displayBoard(gameState.players[0].location, gameState.players[1].location)
    // show the players hands
    for (var pn = 0; pn <= 1; pn++) {
      fillHand(pn, gameState.players[pn].bases, gameState.players[pn].styles)
    }
    // Show the event log.
    $('.event-log').html(gameState['events'].reverse().join("<br/>"))
  }


  // This is for select_attack_pairs choice.
  // ---------------------------------------
  var base
  var setBase = function(baseName) {
    base = baseName.toLowerCase()
    loadCard('base', base.toLowerCase(), $('.my-pair'))
    // This needs to fill in the appropriate image.
    setPair()
  }
  var style
  var setStyle = function(styleName) {
    style = styleName.toLowerCase()
    loadCard('style', style.toLowerCase(), $('.my-pair'))
    // This needs to fill in the appropriate image.
    setPair()
  }
  var setPair = function() {
    if (style && base) {
      $('.js-finalize-attack-pair').show()
    }
  }
  var submitAttackPair = function() {
    $('.js-finalize-attack-pair').hide()
    submitData(style + "_" + base)
    style = undefined
    base = undefined
  }

  // Ajax methods
  var ping = function() {
    console.log('ping.')
    $.get('/ping/' + game_id + '/', {
      'player_id': player_id
    }, function(data) {
      setUI(data)
      setTimeout(ping, 1000)
    }, 'json')
  }
  var submitData = function(str) {
    $.post('/games/' + game_id + '/', {
      'player_id': player_id,
      'action': str
    }, function(data) {
      setUI(data)
    }, 'json')
  }


  // ---------------------------------------

  $(function() {
    $('body').on('click', '.heading', function() {
      $(this).siblings('.collapsable').toggle()
    })
    $('form').on('submit', function() {
      submitData($(this).find('input').val())
      return false;
    })


    $('body').on('click', '.select-me.js-bases .card', function() {
      setBase($(this).text())
    })
    $('body').on('click', '.select-me.js-styles .card', function() {
      setStyle($(this).text())
    })
    $('body').on('click', '.js-submit-attack-pair', function() {
      submitAttackPair()
    })
    $('.js-answers').on('click', '.btn', function() {
      submitData($(this).text())
      $('.js-answers').hide()
    })
    $('.js-choose-character').on('click', '.btn', function() {
      submitData($(this).text())
      $('.js-choose-character').hide()
    })

    ping()
  })
}

var Game = {init: init}
