spec.mixco.behaviour
====================

Tests for behaviours.

Mocks
-----

    mock = require '../mock'

    mockActor = -> createSpyObj 'actor', [
        'send',
        'on',
        'addListener',
        'removeListener' ]

    mockBehaviour = ->
        behaviour = new Behaviour
        spyOn(behaviour, 'enable').andCallThrough()
        spyOn(behaviour, 'disable').andCallThrough()
        behaviour

Module
------

    value = require '../../mixco/value'
    {Output, Map, When, Behaviour} = require '../../mixco/behaviour'


Tests
-----

Tests for the **Output** basic behaviour.

    describe 'Output', ->

        output = null
        actor  = null

        beforeEach ->
            output = new Output
            actor  = do mockActor

        it 'can accept actor without "send"', ->
            actor.send = undefined
            output.enable {}, actor
            output.value = 5
            output.value = 0

        it 'initializes the actor depending on pre-enable value', ->
            output.output.value = 1
            output.enable {}, actor
            expect(actor.send).toHaveBeenCalledWith 'on'

        it 'sends "on" value when value is above or equal minimum', ->
            output.enable {}, actor
            output.output.value = 1
            expect(actor.send).toHaveBeenCalledWith 'on'

        it 'sends "on" value when value is bellow minimum', ->
            output.enable {}, actor
            output.output.value = 1
            output.output.value = 0
            expect(actor.send).toHaveBeenCalledWith 'off'

Tests for the **Map** behaviour

    describe 'Map', ->

        map2   = null
        map    = null
        actor  = null
        script = null

        beforeEach ->
            map    = new Map "[Test]", "test"
            map2   = new Map "[Test]", "test", "[Test2]", "test2"
            actor  = do mockActor
            script = do mock.testScript

        it 'does not listen to the Mixxx control unnecesarily', ->
            actor.send = undefined
            map.enable script, actor
            expect(script.mixxx.engine.connectControl)
                .not.toHaveBeenCalled()

        it 'connects to the Mixxx control when actor has send', ->
            map.enable script, actor
            expect(script.mixxx.engine.connectControl)
                .toHaveBeenCalledWith "[Test]", "test", do script.handlerKey

        it 'connects to output control when different from input', ->
            map2.enable script, actor
            expect(script.mixxx.engine.connectControl)
                .toHaveBeenCalledWith "[Test2]", "test2", do script.handlerKey

        it 'direct maps output to the right parameter', ->
            expect(map.directOutMapping()).toEqual { group: "[Test]",  key: "test" }
            expect(map2.directOutMapping()).toEqual { group: "[Test2]", key: "test2" }

        it 'direct maps input to the right parameter', ->
            expect(map.directInMapping()).toEqual { group: "[Test]",  key: "test" }
            expect(map2.directInMapping()).toEqual { group: "[Test]",  key: "test" }

        it 'connects to the Mixxx control when someone is obsrving "value"', ->
            map.on "value", ->
            map.enable script, actor
            expect(script.mixxx.engine.connectControl)
                .toHaveBeenCalledWith "[Test]", "test", do script.handlerKey

Tests for the **When** behaviour

    describe 'When', ->

        condition = null
        wrapped   = null
        when_     = null
        actor     = null
        script    = null

        beforeEach ->
            condition = new value.Value false
            wrapped   = do mockBehaviour
            actor     = do mockActor
            script    = do mock.testScript
            when_     = new When condition, wrapped

        it "does nothing when enabled and condition not satisifed", ->
            when_.enable script, actor
            expect(wrapped.enable).
                not.toHaveBeenCalled()

        it "enables wrapped when condition is satisfied", ->
            condition.value = true
            when_.enable script, actor
            expect(wrapped.enable).
                toHaveBeenCalledWith script, actor

        it "disables wrapped when it is disabled", ->
            condition.value = true
            when_.enable script, actor
            when_.disable()
            expect(wrapped.disable).
                toHaveBeenCalledWith script, actor

        it "enables or disables wrapped when condition changes", ->
            when_.enable script, actor
            condition.value = true
            expect(wrapped.enable).
                toHaveBeenCalledWith script, actor
            condition.value = false
            expect(wrapped.disable).
                toHaveBeenCalledWith script, actor

        it "generates a new negated version on 'else", ->
            wrapped2 = do mockBehaviour
            else_ = when_.else wrapped2
            condition.value = true
            else_.enable script, actor
            expect(wrapped2.enable).
                not.toHaveBeenCalledWith script, actor
            condition.value = false
            expect(wrapped2.enable).
                toHaveBeenCalledWith script, actor