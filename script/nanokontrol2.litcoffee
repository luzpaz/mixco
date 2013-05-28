script.nanokontrol2
===================

Mixxx script file for the **Korg NanoKontrol2** controller.  The
script is based on the [**Mixco** framework](../index.html).  This
script description is a bit more verbose than others, at it tries to
serve as **tutorial** on how to write your own controller scripts.

  ![NanoKontrol2 Layout](../pic/nanokontrol2.jpg)

License
-------

>  Copyright (C) 2013 Juan Pedro Bolívar Puente
>
>  This program is free software: you can redistribute it and/or
>  modify it under the terms of the GNU General Public License as
>  published by the Free Software Foundation, either version 3 of the
>  License, or (at your option) any later version.
>
>  This program is distributed in the hope that it will be useful,
>  but WITHOUT ANY WARRANTY; without even the implied warranty of
>  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
>  GNU General Public License for more details.
>
>  You should have received a copy of the GNU General Public License
>  along with this program.  If not, see <http://www.gnu.org/licenses/>.


Dependencies
------------

First, we have to import he *Mixco* modules that we are going to use.

    script    = require "../mixco/script"
    control   = require "../mixco/control"
    behaviour = require "../mixco/behaviour"


The script
----------

### Declaration

We start defining the script by creating a class that is called like
the file but with
[*CamelCase*](http://en.wikipedia.org/wiki/CamelCase) and inherits
from `script.Script`. We have to register it too, and in CoffeeScript
we can do this all in one line.

    script.register module, class NanoKontrol2 extends script.Script

### Metadata

Then we fill out the metadata. This will be shown to the user in the
preferences window in Mixxx when he selects the script.

        info:
            name: '[mixco] Korg Nanokontrol 2'
            author: 'Juan Pedro Bolivar Puente <raskolnikov@gnu.org>'
            description:
                """
                Controller mapping for Korg Nanokontrol 2 that is
                targetted at being used as main interface for Mixxx.
                """
            forums: ''
            wiki: ''

### Basic deck controls

Lets define these couple of shortcuts.

        c = control
        b = behaviour

### Constructor

All the actual interesting stuff happens in the *constructor* of the
script. Here we will create the controls and add them to the script
and define their behaviour.

        constructor: ->
            super

#### Transport section

All the buttons on the left side of the controllers is what we call
the *transport section*. These are global buttons

The *cycle* button will be used as modifier.

            @cycle = do b.modifier
            @add c.ledButton(0x2e).does @cycle

Most of the transport controls will have their behaviour defined
per-deck. We define them here and add the behaviours later.

            @add @backButton      = c.ledButton 0x3a
            @add @fwdButton       = c.ledButton 0x3b
            @add @nudgeDownButton = c.ledButton 0x2b
            @add @nudgeUpButton   = c.ledButton 0x2c

Note that we here abused the expresivity of CoffeeScript, where it can
in many cases omit parentheses. Any of those was equivalent to writting:

>    this.backButton = c.ledButton(0x2b)
>    this.add(this.backButton)


Then, we create a chooser object over the *pfl* (prehear) parameter,
so we will have only one channel with prehear activated at a time.
Also, this will let us change the behaviour of some *transport*
controls depending on which deck is *selected* -- i.e, has prehear
enabled.

            @decks = b.chooser "pfl"

#### Deck controls

Finally we add the per-deck controls, that are defined in `addDeck`.

            @addDeck 0
            @addDeck 1

        addDeck: (i) ->
            g = "[Channel#{i+1}]"

The top 8 knobs are mapped to the two decks mixer filter section (low,
mid, high, gain).

            @add c.knob(0x10 + 4*i).does g, "filterLow"
            @add c.knob(0x11 + 4*i).does g, "filterMid"
            @add c.knob(0x12 + 4*i).does g, "filterHigh"
            @add c.knob(0x13 + 4*i).does b.soft g, "pregain"

Then the two first "control sections" are mapped like:

  * S: Selects the deck for prehear.
  * M: Cue button for the deck.
  * R: Play button for the deck.
  * The fader controls the volume of the deck.

            @add c.ledButton(0x20 + 4*i).does @decks.choose i
            @add c.ledButton(0x30 + 4*i).does g, "cue_default"
            @add c.ledButton(0x40 + 4*i).does g, "play"
            @add c.slider(0x00 + 4*i).does g, "volume"

The next two control sections control the pitch related stuff and
effects.

  * S: Synchronises to the other track.
  * M: Toggles key lock.
  * R: Enables flanger.
  * The fader controls the pitch of the deck.


            @add c.ledButton(0x21 + 4*i).does g, "beatsync"
            @add c.ledButton(0x31 + 4*i).does g, "keylock"
            @add c.ledButton(0x41 + 4*i).does g, "flanger"
            @add c.slider(0x01 + 4*i).does b.soft g, "rate"

Depending on the selected track we map some of the transport buttons.
For example, the *track<* and *track>* buttons control the selected
track *fast forward* and *fast rewind*.

            @fwdButton.when @decks.choose(i), g, "fwd"
            @backButton.when @decks.choose(i), g, "back"

The << and >> buttons are a bit more complicated. We want them to
behave as *nudge* buttons for the selected track, but we want the
*cycle* modifier to change the nudge speed. We use the `behaviour.and`
condition combinator to mix the conditions. We also use `control.elseWhen`
to simplify the negative condition.

            chooseCycle = b.and @cycle, @decks.choose i
            @nudgeUpButton
                .when(chooseCycle, g, "rate_temp_up")
                .elseWhen @decks.choose(i), g, "rate_temp_up_small"
            @nudgeDownButton
                .when(chooseCycle, g, "rate_temp_down")
                .elseWhen @decks.choose(i), g, "rate_temp_down_small"

### Initialization

The **init** method is called by Mixxx when the script is loaded. Here
we can initialize the state of Mixxx. In our case, we select the first
deck, such that all transport buttons are directly functional.

        init: ->
            super
            @decks.select 0
