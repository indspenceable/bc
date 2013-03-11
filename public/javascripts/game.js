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
    //return (pn == player_id ? $(".js-mine") : $('.js-theirs'))
    return $('.js-p' + pn)
  }

  var makeCard = function(range, power, priority, _data) {
    data = _data || {}
    data.range = "" + range
    data.power = "" + power
    data.priority = "" + priority
    return data
  }

  var characterUAs = {
    hikaru: "Hikaru has four elemental tokens each with a different bonus. Each beat, he may ante one token to get its effect, and then it is discarded. He regains tokens by using his styles, but may not regain any that he spent this turn.",
    cadenza: "Cadenza has 3 iron body tokens. Each beat, he may ante one for stun immunity that beat; additionally, every time he takes damage, he can spend one for (stun guard ∞)",
    khadath: "Khadath's styles allow him to place his gate trap. Opponents that move on immediately end that movement effect (You can move as you please starting on the trap). At reveal, opponents next to the trap get -1 priority, and opponents standing on top of the trap get -3 priority.",
    rukyuk: "Rukyuk has 6 ammo tokens, each with a different bonus. Each turn he may ante one of them to get its bonus. If he doesn't ante any, he does not hit this beat."
  }

  var cardDefinitions = {
    emptyCard: makeCard('', '', '', {}),
    dash: makeCard("N/A", "N/A", 9, {"After Activating": "Move 1, 2, or 3 spaces. If you switch sides with an opponent, they cannot hit you this turn."}),
    grasp: makeCard(1, 2, 5, {"On Hit": "Move opponent 1 space."}),
    drive: makeCard(1, 3, 4, {"Before Activating": "Advance 1 or 2 spaces."}),
    strike: makeCard(1, 4, 3, {"Stun Guard": "5"}),
    shot: makeCard("1~4", 3, 2, {"Stun Guard": "2"}),
    burst: makeCard("2~3", 3, 1, {"Start of Beat": "Retreat 1 or 2 spaces."}),

    // Hikaru
    palmstrike: makeCard(1, 2, 5, {"Start of Beat": "Advance 1 space.", "On Damage": "Recover an elemental token of your choice."}),
    geomantic: makeCard(0, 1, 0, {"Start of Beat": "You may ante another token for this beat."}),
    focused: makeCard(0, 1, 0, {"On Hit": "Recover an elemental token of your choice."}),
    trance: makeCard("0~1", 0, 0, {"Start of Beat": "Return all anted tokens to your pool. You don't get their effects this turn.", "End of Beat": "Recover an elemental token of your choice."}),
    sweeping: makeCard(0, -1, 3, {"If hikaru gets hit this turn, he takes 2 additional damage.": undefined}),
    advancing: makeCard(0, 1, 1, {"Start of beat": "Advance 1 space. If this causes you to switch sides with an opponent, you get +1 power this beat."}),
    // Finishers
    wrathofelements: makeCard(1, 7, 6, {"Reveal": "Immediately ante all available tokens and apply them to this attack."}),
    fourwinds: makeCard(1, 2, 5, {"Before Activating": "Advance up to one space.", "On Hit": "Regain an elemental token. If you do, repeat this attack."}),

    //Cadenza
    battery: makeCard(0, 1, -1, {"You get +4 priority next beat.": undefined}),
    clockwork: makeCard(0, 3, -3, {"Soak": 3}),
    hydraulic: makeCard(0, 2, -1, {"Before Activating": "Advance 1 space.", "Soak": 1}),
    mechanical: makeCard(0, 2, -2, {"End of Beat": "Advance up to 3 spaces."}),
    grapnel: makeCard("2~4", 0, 0, {"On Hit": "Pull opponent up to 3 spaces."}),
    press: makeCard("1~2", 1, 0, {"Stun Guard": 2, "+1 damage for each point of damage you have taken this beat.": undefined}),
    // Finishers
    rocketpress: makeCard(1, 8, 0, {"Soak": 3, "Stun Immunity": undefined, "Before Activating": "Advance 2 or more spaces."}),
    feedbackfield: makeCard("1~2", 1, 0, {"Soak": 5, "On Hit": "This attack has +2 power for each point of damage Cadenza soaked this beat."}),

    // Khadath
    hunters: makeCard(0, 1, 0, {"reveal": "+2 Power +2 Priority if opponent is on or next to your trap."}),
    teleport: makeCard("0~2", 1, -4, {"Ranged attacks don't hit you if your trap is between you and your opponnent.": undefined, "End of Beat": "Move to any unoccupied space. Move your trap to any unoccupied space."}),
    blight: makeCard("0~2", 0, 0, {"Start of Beat": "Place your trap anywhere in your range."}),
    evacuation: makeCard("0~1", 0, 0, {"Start of Beat": "Place your trap in your current location, then retreat 1 space."}),
    lure: makeCard("0~5", -1, -1, {"On Hit": "Pull your opponent any number of spaces."}),
    snare: makeCard("X", 3, 1, {"The range of this attack includes the space occupied by your trap, and the adjacent spaces.": undefined, "You can't move your trap this beat.": undefined, "Stun Immunity": undefined}),
    // Finishers
    dimensionalexile: makeCard("N/A", 25, 0, {"Stun Immunity. The range of this attack is the space occupied by Khadath's trap.": undefined}),
    planarcrossing: makeCard("1~2", 4, 5, {"On Hit": "Rearrange the board however you like, moving all characters and markers to legal positions."}),

    // Rukyuk
    trick: makeCard("1~2", 0, -3, {"Stun Immunity": undefined}),
    sniper: makeCard("3~6", 1, 2, {"After Activating": "Move 1, 2, or 3 spaces"}),
    crossfire: makeCard("2~3", 0, -2, {"Soak": 2, "On Hit": "Discard any token from your ammo pool for +2 power this beat."}),
    pointblank: makeCard("0~1", 0, 0, {"Stun Guard": 2, "On Damage": "Push your opponent up to 2 spaces"}),
    gunner: makeCard("2~4", 0, 0, {"Before Activating": "Discard any ammo token from your ammo pool for -1~+1 range this beat.", "After Activating": "Move 1 or 2 spaces."}),
    reload: makeCard("N/A", "N/A", 4, {"After Actvating": "Move directly to any unoccupied space.", "End of Beat": "Recover all ammo tokens."}),
    // Finishers
    fullyautomatic: makeCard("3~6", 2, 6, {"Do not apply the effects of ammo tokens to this attack.": undefined, "On Hit":"You may discard an ammo token to execute this attack again."}),
    forcegrenade: makeCard("1~2", 4, 4, {"Do not apply the effects of ammo tokens to this attack. This attack hits even if an ammo token was not anted.": undefined, "On Hit": "Push the opponent any number of spaces.", "After Activating": "Retreat any number of spaces."}),

    // Reggie
    critical: makeCard(0, -1, 1, {"This attack ignores stun guard.": undefined, "On Hit, Range 1": "Spend a dark force token to get +3 power."}),
    rasping: makeCard('0~1', -1, 1, {"On Hit, Range 1": "Spend a dark force token to get +3 power."}),
    merciless: makeCard('0~1', -1, 1, {"If your opponent passes you this beat, they lose 2 life and can't move any more this beat.": undefined, "After Activating": "If you have a dark force token, do not get hit by attacks for the rest of this beat."}),
    psycho: makeCard(0, 0, 1, {"Start of Beat": "Advance until you are adjacent to your opponent.", "End of Beat, Range 1": "Spend a dark force token to repeat this attack."}),
    assassin: makeCard(0, 0, 0, {"On Hit": "Retreat any number of spaces.", "On Damage, Range 1": "You may spend a dark force token. If you do, the opponent cannot move next beat."}),
    knives: makeCard("1~2",4,5, {"This attack does not stun at range one.": undefined, "This attack wins priority ties without clashing.": undefined}),

    // Zaam
    malicious: makeCard(0, 1, -1, {"Stun Guard": 2, "After Activating": "You may assume the paradigm of pain."}),
    warped: makeCard("0~2", 0, 0, {"Start of Beat": "Retreat 1 Space.", "After Activating": "You may assume the paradigm of distortion."}),
    sturdy: makeCard(0, 1, -1, {"Stun Immunity": 2, "Ignore all movement effects applied to you this beat.": undefined, "After Activating": "You may assume the paradigm of resilience."}),
    urgent: makeCard("0~1", -1, 2, {"Before Activating": "Advance up to one space.", "After Activating": "You may assume the paradigm of haste."}),
    sinuous: makeCard(0, 0, 1, {"Stun Guard": 2, "After Activating": "You may assume the paradigm of fluidity."}),
    paradigmshift: makeCard("2~3", 3, 3, {"Before Activating": "Assume the paradigm of your choice."})
  }
  var loadCard = function(cardName, $card, overrideCardName) {
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
    return $card;
  }
  var clearCard = function($card) {
    loadCard('emptyCard', $card, "");
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
  var fillCards = function(pn, currentBase, currentStyle, specialAction, bases, styles, tokens, discard1Cards, discard2Cards) {
    if (currentBase) {
      loadCard(currentBase.toLowerCase(), $root(pn).filter('.attack-pair').find('.real.base'))
    } else {
      clearCard($root(pn).filter('.attack-pair').find('.real.base'))
    }
    if (currentStyle) {
      loadCard(currentStyle.toLowerCase(), $root(pn).filter('.attack-pair').find('.real.style'))
    } else {
      clearCard($root(pn).filter('.attack-pair').find('.real.style'))
    }
    if (specialAction) {
      $root(pn).filter('.attack-pair').hide();
      $root(pn).filter('.special-action').show()
      loadCard(specialAction.toLowerCase(), $root(pn).filter('.special-action').find('.special-action-card'))
    } else {
      $root(pn).filter('.attack-pair').show();
      $root(pn).filter('.special-action').hide()
    }
    var $bases = $root(pn).find('.js-bases').empty()
    var $styles = $root(pn).find('.js-styles').empty()
    var $tokens = $root(pn).find('.js-tokens').empty()
    var $discard1 = $root(pn).find('.js-discard1').empty()
    var $discard2 = $root(pn).find('.js-discard2').empty()

    var $template = $('#template-card')
    for (var index in bases) {
      $('<div/>').addClass('card mini-card base').text(bases[index]).popover({
        html: true,
        trigger: 'hover',
        title: bases[index],
        content: loadCard(bases[index], $template.clone()).html()
        }).appendTo($bases)
    }
    for (var index in styles) {
      $('<div/>').addClass('card mini-card style').text(styles[index]).popover({
        html: true,
        trigger: 'hover',
        title: styles[index],
        content: loadCard(styles[index], $template.clone()).html()
        }).appendTo($styles)
    }
    for (var index in tokens) {
      $('<div/>').addClass('token').text(tokens[index]).appendTo($tokens)
    }
    for (var index in discard1Cards) {
      $('<div/>').addClass('card mini-card').text(discard1Cards[index]).popover({
        html: true,
        trigger: 'hover',
        title: discard1Cards[index],
        content: loadCard(bases[index], $template.clone()).html()
        }).appendTo($discard1)
    }
    for (var index in discard2Cards) {
      var currentClass = (index == 0 ? 'style' : 'base')
      $('<div/>').addClass('card mini-card').text(discard2Cards[index]).popover({
        html: true,
        trigger: 'hover',
        title: discard2Cards[index],
        content: loadCard(bases[index], $template.clone()).html()
        }).appendTo($discard2)
    }
  }

  var setExtraData = function(pn, data) {
    if (data.trap) {
      var color = (pn == 0 ? 'info' : 'important')
      $('.board').find('.s' + data.trap).append($("<span/>").addClass("label label-" + color).html($('<i/>').addClass('icon-asterisk')))
    }
  }

  var needInputAlready = true
  var chime = new Audio("/audio/chime.wav")
  var windowActive = window.isActive

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
      if (!needInputAlready && !windowActive) {
        chime.play()
      }
      needInputAlready = true
      setFaviconToAlert();
    } else {
      needInputAlready = false
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
        gameState.players[pn].special_action,
        gameState.players[pn].bases,
        gameState.players[pn].styles,
        gameState.players[pn].token_pool,
        gameState.players[pn].discard1,
        gameState.players[pn].discard2)
      // Display player life
      $root(pn).filter('.life').text("P" + pn + ": " + gameState.players[pn].life + " Life")
      $root(pn).filter('.js-current-effects').html(gameState.players[pn].current_effects.join("<br/>"))
      $('.p' + pn + 'header').find('.character-desc').text(characterUAs[gameState.players[pn].character_name])
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
    loadCard(base.toLowerCase(), $root(player_id).filter('.attack-pair').find('.base.real'))
    // This needs to fill in the appropriate image.
    setPair()
  }
  var style
  var setStyle = function(styleName) {
    style = styleName.toLowerCase()
    loadCard(style.toLowerCase(), $root(player_id).filter('.attack-pair').find('.style.real'))
    // This needs to fill in the appropriate image.
    setPair()
  }
  var setPair = function() {
    if ((style || need=="base") && base) {
      $root(player_id).find('.js-finalize-attack-pair').show()
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

    $(window).focus(function() {windowActive=true})
    $(window).blur(function() {windowActive=false})

    ping()
  })
}

var Game = {init: init}
