class MockStore
  create: (data) ->
    dfd = new $.Deferred()
    dfd.resolve($.extend({id: 123}, data))
    return dfd.promise()

  update: (data) ->
    dfd = new $.Deferred()
    dfd.resolve($.extend({}, data))
    return dfd.promise()

  delete: (data) ->
    dfd = new $.Deferred()
    dfd.resolve()
    return dfd.promise()

  query: (data) ->
    dfd = new $.Deferred()
    dfd.resolve([{id: 1}, {id: 2}], {total:2})
    return dfd.promise()

describe 'Annotator.Registry', ->
  m = null
  r = null

  beforeEach ->
    m = new MockStore()
    r = new Annotator.Registry(m)

  it 'should take a Store plugin as its first constructor argument', ->
    assert.equal(r.store, m)

  describe '#create()', ->

    it "should pass annotation data to the store's #create()", ->
      sinon.spy(m, 'create')

      r.create({some: 'data'})
      assert(m.create.calledOnce, 'store .create() called once')
      assert(
        m.create.calledWith({some: 'data'}),
        'store .create() called with correct args'
      )

      m.create.reset()

    it "should return a promise resolving to the created annotation", (done) ->
      r.create({some: 'data'})
        .done (r) ->
          assert.deepEqual(r, {id: 123, some: 'data'})
          done()
        .fail (obj, msg) ->
          done(new Error("promise rejected: #{msg}"))

  describe '#update()', ->

    it "should return a rejected promise if the data lacks an id", (done) ->
      r.update({some: 'data'})
        .done ->
          done(new Error("promise unexpectedly resolved"))
        .fail (ann, msg) ->
          assert.deepEqual(ann, {some: 'data'})
          assert.include(msg, ' id ')
          done()

    it "should pass annotation data to the store's #update()", ->
      sinon.spy(m, 'update')

      r.update({id: 123, some: 'data'})
      assert(m.update.calledOnce, 'store .update() called once')
      assert(
        m.update.calledWith({id: 123, some: 'data'}),
        'store .update() called with correct args'
      )

      m.update.reset()

    it "should return a promise resolving to the updated annotation", (done) ->
      r.update({id:123, some: 'data'})
        .done (r) ->
          assert.deepEqual(r, {id: 123, some: 'data'})
          done()
        .fail (obj, msg) ->
          done(new Error("promise rejected: #{msg}"))

  describe '#delete()', ->

    it "should return a rejected promise if the data lacks an id", (done) ->
      r.delete({some: 'data'})
        .done ->
          done(new Error("promise unexpectedly resolved"))
        .fail (ann, msg) ->
          assert.deepEqual(ann, {some: 'data'})
          assert.include(msg, ' id ')
          done()

    it "should pass annotation data to the store's #delete()", ->
      sinon.spy(m, 'delete')

      r.delete({id: 123, some: 'data'})
      assert(m.delete.calledOnce, 'store .delete() called once')
      assert(
        m.delete.calledWith({id: 123, some: 'data'}),
        'store .delete() called with correct args'
      )

      m.delete.reset()

    it "should return a promise", (done) ->
      r.delete({id:123, some: 'data'})
        .done () ->
          done()
        .fail (obj, msg) ->
          done(new Error("promise rejected: #{msg}"))

  describe '#query()', ->

    it "should pass query data to the store's #query()", ->
      sinon.spy(m, 'query')

      r.query({foo: 'bar', type: 'giraffe'})
      assert(m.query.calledOnce, 'store .query() called once')
      assert(
        m.query.calledWith({foo: 'bar', type: 'giraffe'}),
        'store .query() called with correct args'
      )

      m.query.reset()

    it "should return a promise", (done) ->
      r.query({foo: 'bar', type: 'giraffe'})
        .done () ->
          done()
        .fail (obj, msg) ->
          done(new Error("promise rejected: #{msg}"))

  describe '#load()', ->

    it "should pass query data to the store's #query()", ->
      sinon.spy(m, 'query')

      r.load({foo: 'bar', type: 'giraffe'})
      assert(m.query.calledOnce, 'store .query() called once')
      assert(
        m.query.calledWith({foo: 'bar', type: 'giraffe'}),
        'store .query() called with correct args'
      )

      m.query.reset()

    it "should return a promise", (done) ->
      r.load({foo: 'bar', type: 'giraffe'})
        .done () ->
          done()
        .fail (obj, msg) ->
          done(new Error("promise rejected: #{msg}"))
