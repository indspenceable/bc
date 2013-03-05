function capitaliseFirstLetter(string)
{
    return string.charAt(0).toUpperCase() + string.slice(1);
}

var init = function(player_id, game_id, character_names) {
  var cachedInputNumber = -1;
  var cachedRequiredInput;

  var need;
  var needAlert = false;
  var faviconTimeout = 100;

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
    emptyCard: makeCard('', '', '', {}),
    dash: makeCard("N/A", "N/A", 9, {"After Activating": "Move 1, 2, or 3 spaces. If you switch sides with an opponent, they cannot hit you this turn."}),
    grasp: makeCard(1, 2, 5, {"On Hit": "Move opponent 1 space."}),
    drive: makeCard(1, 3, 4, {"Before Activating": "Advance 1 or 2 spaces."}),
    strike: makeCard(1, 4, 3, {"Stun Guard": "5"}),
    shot: makeCard("1~4", 3, 2, {"Stun Guard": "2"}),
    burst: makeCard("2~3", 3, 1, {"Start of Beat": "Retreat 1 or 2 spaces."}),

    //Hikaru
    palmstrike: makeCard(1, 2, 5, {"Start of Beat": "Advance 1 space.", "On Damage": "Recover an elemental token of your choice."}),
    geomantic: makeCard(0, 1, 0, {"Start of Beat": "You may ante another token for this beat."}),
    focused: makeCard(0, 1, 0, {"On Hit": "Recover an elemental token of your choice."}),
    trance: makeCard("0~1", 0, 0, {"Start of Beat": "Return all anted tokens to your pool. You don't get their effects this turn.", "End of Beat": "Recover an elemental token of your choice."}),
    sweeping: makeCard(0, -1, 3, {"passive": "If hikaru gets hit this turn, he takes 2 additional damage."}),
    advancing: makeCard(0, 1, 1, {"Start of beat": "Advance 1 space. If this causes you to switch sides with an opponent, you get +1 power this beat."}),

    //Cadenza
    battery: makeCard(0, 1, -1, {"passive": "You get +4 priority next beat."}),
    clockwork: makeCard(0, 3, -3, {"Soak": 3}),
    hydraulic: makeCard(0, 2, -1, {"Before Activating": "Advance 1 space."}),
    mechanical: makeCard(0, 2, -2, {"End of Beat": "Advance up to 3 spaces."}),
    grapnel: makeCard("2~4", 0, 0, {"On Hit": "Pull opponent up to 3 spaces."}),
    press: makeCard("1~2", 1, 0, {"Stun Guard": 2, "passive": "Deals additional damage equal to the ammount of damage you have taken this beat."}),

    // Khadath
    hunters: makeCard(0, 1, 0, {"reveal": "+2 Power +2 Priority if opponent is on or next to your trap."}),
    teleport: makeCard("0~2", 1, -4, {"passive": "Ranged attakcs don't hit you if your trap is between you and your opponnent.", "End of Beat": "Move to any unoccupied space. Move your trap to any unoccupied space."}),
    blight: makeCard("0~2", 0, 0, {"Start of Beat": "Place your trap anywhere in your range."}),
    evacuation: makeCard("0~1", 0, 0, {"Start of Beat": "Place your trap in your current location, then retreat 1 space."}),
    lure: makeCard("0~5", -1, -1, {"On Hit": "Pull your opponent any number of spaces."}),
    snare: makeCard("X", 3, 1, {"passive": "This attack hits opponents on or adjacent to your trap. You can't move your trap this beat.", "Stun Immunity": undefined}),

    trick: makeCard("1~2", 0, -3, {'passive': "Stun Immunity"}),
    sniper: makeCard("3~6", 1, 2, {"After Activating": "Move 1, 2, or 3 spaces"}),
    crossfire: makeCard("2~3", 0, -2, {"Soak": 2, "On Hit": "Discard any token from your ammo pool for +2 power this beat."}),
    pointblank: makeCard("0~1", 0, 0, {"Stun Guard": 2, "On Damage": "Push your opponent up to 2 spaces"}),
    gunner: makeCard("2~4", 0, 0, {"Before Activating": "Discard any ammo token from your ammo pool for -1~+1 range this beat.", "After Activating": "Move 1 or 2 spaces."}),
    reload: makeCard("N/A", "N/A", 4, {"After Actvating": "Move directly to any unoccupied space.", "End of Beat": "Recover all ammo tokens."})

  }
  var loadCard = function(styleOrBase, cardName, $pair, overrideCardName) {
    var $card = $pair.find('.' + styleOrBase)
    $card.find('.name').text(overrideCardName || capitaliseFirstLetter(cardName))
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
        $card.find('.effects').append($('<p/>').html("<b>" + attr +
          (card[attr] ? (":</b> " + card[attr]) : ("</b>")))
        )
      }
    }
  }
  var clearCard = function(styleOrBase, $pair) {
    loadCard(styleOrBase, 'emptyCard', $pair, "");
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
    need = 'both'
  }
  var selectBase = function() {
    $root(player_id).find('.js-bases').addClass("select-me")
    need = 'base'
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
    } else if (/^select_base/.test(question)) {
      selectBase()
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
    $('.board').find('.s' + p0).append($("<span/>").addClass("label label-info").html($('<i/>').addClass('icon-user')))
    $('.board').find('.s' + p1).append($("<span/>").addClass("label label-important").html($('<i/>').addClass('icon-user')))
  }
  var fillCards = function(pn, currentBase, currentStyle, bases, styles, tokens, discard1Cards, discard2Cards) {
    if (currentBase) {
      loadCard('base', currentBase.toLowerCase(), $root(pn).filter('.attack-pair'))
    } else {
      clearCard('base', $root(pn).filter('.attack-pair'))
    }
    if (currentStyle) {
      loadCard('style', currentStyle.toLowerCase(), $root(pn).filter('.attack-pair'))
    } else {
      clearCard('style', $root(pn).filter('.attack-pair'))
    }
    var $bases = $root(pn).find('.js-bases').empty()
    var $styles = $root(pn).find('.js-styles').empty()
    var $tokens = $root(pn).find('.js-tokens').empty()
    var $discard1 = $root(pn).find('.js-discard1').empty()
    var $discard2 = $root(pn).find('.js-discard2').empty()
    for (var index in bases) {
      $('<div/>').addClass('card').text(bases[index]).appendTo($bases)
    }
    for (var index in styles) {
      $('<div/>').addClass('card').text(styles[index]).appendTo($styles)
    }
    for (var index in tokens) {
      $('<div/>').addClass('token').text(tokens[index]).appendTo($tokens)
    }
    for (var index in discard1Cards) {
      $('<div/>').addClass('card').text(discard1Cards[index]).appendTo($discard1)
    }
    for (var index in discard2Cards) {
      $('<div/>').addClass('card').text(discard2Cards[index]).appendTo($discard2)
    }
  }

  var setExtraData = function(pn, data) {
    if (data.trap) {
      $('.board').find('.s' + data.trap).append("P" + pn + "'s Trap")
    }
  }

  var setUI = function(data) {
    // short circuit unless more events have happened, or
    // there is a new question.
    if (data.gameState && data.gameState.input_number == cachedInputNumber &&
      data.requiredInput == cachedRequiredInput) {
      return;
    }
    // Set the cache so we'll shortcircuit next time.
    cachedInputNumber = data.gameState.input_number;
    cachedRequiredInput = data.requiredInput

    console.log(data)

    $('.js-loading').hide()
    $('.js-in-game').show()

    // Do everything required for this question.
    var requiredInput = data['requiredInput']
    setup_inputs(requiredInput)

    if (requiredInput) {
      setFaviconToAlert();
    } else {
      setFaviconToDefault();
    }

    if (!needAlert && requiredInput) {
      needAlert = requiredInput
      setFaviconToAlert();
    }
    needAlert = requiredInput


    // Updates related to the gamestate
    var gameState = data['gameState']
    if (!gameState.players) { return }
    // current beat
    if(gameState.current_beat) {
      $('.js-current-beat').html("<h3>" + gameState.current_beat + "</h3>")
    }
    // Display the board
    displayBoard(gameState.players[0].location, gameState.players[1].location)
    // show the players hands
    for (var pn = 0; pn <= 1; pn++) {
      fillCards(pn,
        gameState.players[pn].current_base,
        gameState.players[pn].current_style,
        gameState.players[pn].bases,
        gameState.players[pn].styles,
        gameState.players[pn].token_pool,
        gameState.players[pn].discard1,
        gameState.players[pn].discard2)
      // Display player life
      $root(pn).filter('.life').text("P" + pn + ": " + gameState.players[pn].life + " Life")
      $root(pn).filter('.js-current-effects').html(gameState.players[pn].current_effects.join("<br/>"))
      setExtraData(pn, gameState.players[pn].extra_data)
    }
    // Show the event log.
    $('.event-log').html(gameState['events'].reverse().join("<br/>"))
  }


  // This is for select_attack_pairs choice.
  // ---------------------------------------
  var base
  var setBase = function(baseName) {
    base = baseName.toLowerCase()
    loadCard('base', base.toLowerCase(), $root(player_id).filter('.attack-pair'))
    // This needs to fill in the appropriate image.
    setPair()
  }
  var style
  var setStyle = function(styleName) {
    style = styleName.toLowerCase()
    loadCard('style', style.toLowerCase(), $root(player_id).filter('.attack-pair'))
    // This needs to fill in the appropriate image.
    setPair()
  }
  var setPair = function() {
    if ((style || need=="base") && base) {
      $('.js-finalize-attack-pair').show()
    }
  }
  var submitAttackPair = function() {
    $('.js-finalize-attack-pair').hide()
    if (need == "base") {
      submitData(base)
    } else {
      submitData(style + "_" + base)
    }
    style = undefined
    base = undefined
  }

  // Ajax methods
  var ping = function() {
    console.log('ping.')
    $.get('/games/' + game_id + '.json', {
    }, function(data) {
      setUI(data)
      setTimeout(ping, 1000)
    }, 'json')
  }
  var submitData = function(str) {
    $.ajax('/games/' + game_id + '/', {
      data: {
        'message': str
      },
      method: 'PUT',
      success: function(data) {
        setUI(data)
      }
    })
  }

  var setFaviconToAlert = function() {
    // if (needAlert) {
    $("#favicon").attr("href","/alert-favicon.png");
    //   setTimeout(setFaviconToDefault, faviconTimeout)
    // }
  }
  var setFaviconToDefault = function() {
    $("#favicon").attr("href","/favicon.gif");
    // setTimeout(setFaviconToAlert, faviconTimeout)
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
      submitData($(this).attr('charactername'))
      $('.js-choose-character').hide()
    })

    ping()
  })
}

var Game = {init: init}
