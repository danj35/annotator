class DelegatedExample extends Delegator
  events:
    'div click': 'pushA'
    'baz': 'pushB'

  options:
    foo: "bar"
    bar: (a) -> a

  constructor: (elem) ->
    super
    @returns = []

  pushA: -> @returns.push("A")
  pushB: -> @returns.push("B")
  pushC: -> @returns.push("C")

describe 'Delegator', ->
  delegator = null
  $fix = null

  beforeEach ->
    addFixture('delegator')

    delegator = new DelegatedExample(fix())
    $fix = $(fix())

  afterEach -> clearFixtures()

  describe "options", ->
    it "should provide access to an options object", ->
      assert.equal(delegator.options.foo, "bar")
      delegator.options.bar = (a) -> "<#{a}>"

    it "should be unique to an instance", ->
      assert.equal(delegator.options.bar("hello"), "hello")

  describe "addEvent", ->
    it "adds an event for a selector", ->
      delegator.addEvent('p', 'foo', 'pushC')

      $fix.find('p').trigger('foo')
      assert.deepEqual(delegator.returns, ['C'])

    it "adds an event for an element", ->
      delegator.addEvent($fix.find('p').get(0), 'bar', 'pushC')

      $fix.find('p').trigger('bar')
      assert.deepEqual(delegator.returns, ['C'])

    it "uses event delegation to bind the events", ->
      delegator.addEvent('li', 'click', 'pushB')

      $fix.find('ol').append("<li>Hi there, I'm new round here.</li>")
      $fix.find('li').click()

      assert.deepEqual(delegator.returns, ['B', 'A', 'B', 'A'])

  it "automatically binds events described in its events property", ->
    $fix.find('p').click()
    assert.deepEqual(delegator.returns, ['A'])

  it "will bind events in its events property to its root element if no selector is specified", ->
    $fix.trigger('baz')
    assert.deepEqual(delegator.returns, ['B'])

  describe "on", ->
    it "should be an alias of Delegator#subscribe()", ->
      assert.strictEqual(delegator.on, delegator.subscribe)

  describe "subscribe", ->
    it "should bind an event to the Delegator#element", ->
      callback = sinon.spy()
      delegator.subscribe('custom', callback)

      delegator.element.trigger('custom')
      assert(callback.called)

    it "should remove the event object from the parameters passed to the callback", ->
      callback = sinon.spy()
      delegator.subscribe('custom', callback)

      delegator.element.trigger('custom', ['first', 'second', 'third'])
      assert(callback.calledWith('first', 'second', 'third'))

    it "should ensure the bound function is unbindable", ->
      callback = sinon.spy()

      delegator.subscribe('custom', callback)
      delegator.unsubscribe('custom', callback)
      delegator.publish('custom')

      assert.isFalse(callback.called)

    it "should not bubble custom events", ->
      callback = sinon.spy()
      $('body').bind('custom', callback)

      delegator.element = $('<div />').appendTo('body')
      delegator.publish('custom')

      assert.isFalse(callback.called)

  describe "unsubscribe", ->
    it "should unbind an event from the Delegator#element", ->
      callback = sinon.spy()

      delegator.element.bind('custom', callback)
      delegator.unsubscribe('custom', callback)
      delegator.element.trigger('custom')

      assert.isFalse(callback.called)

      callback = sinon.spy()

      delegator.element.bind('custom', callback)
      delegator.unsubscribe('custom')
      delegator.element.trigger('custom')

      assert.isFalse(callback.called)

    describe "publish", ->
      it "should trigger an event on the Delegator#element", ->
        callback = sinon.spy()
        delegator.element.bind('custom', callback)

        delegator.publish('custom')
        assert(callback.called)

    describe "isCustomEvent", ->
      events = [
        ['click', false]
        ['mouseover', false]
        ['mousedown', false]
        ['submit', false]
        ['load', false]
        ['click.namespaced', false]
        ['save', true]
        ['cancel', true]
        ['update', true]
      ]

      it "should return true if the string passed is a custom event", ->
        while events.length
          [event, result] = events.shift()
          assert.equal(delegator.isCustomEvent(event), result)
