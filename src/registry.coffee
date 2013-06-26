error = (obj, message) ->
  dfd = new $.Deferred()
  dfd.reject(obj, message)
  return dfd.promise()

class Annotator.Registry extends Delegator
  constructor: (@store) ->

  create: (obj) ->
    return @store.create(obj)

  update: (obj) ->
    if not obj.id?
      return error(obj, "annotation must have an id for update()")

    return @store.update(obj)

  delete: (obj) ->
    if not obj.id?
      return error(obj, "annotation must have an id for delete()")

    return @store.delete(obj)

  query: (query) ->
    return @store.query(query)

  load: (query) ->
    return this.query(query)

  # Public: Creates and returns a new annotation object. Publishes the
  # 'beforeAnnotationCreated' event to allow the new annotation to be modified.
  #
  # Examples
  #
  #   annotator.createAnnotation() # Returns {}
  #
  #   annotator.on 'beforeAnnotationCreated', (annotation) ->
  #     annotation.myProperty = 'This is a custom property'
  #   annotator.createAnnotation() # Returns {myProperty: "This is a…"}
  #
  # Returns a newly created annotation Object.
  createAnnotation: () ->
    annotation = {}
    this.publish('beforeAnnotationCreated', [annotation])
    annotation

  # Public: Initialises an annotation either from an object representation or
  # an annotation created with Annotator#createAnnotation(). It finds the
  # selected range and higlights the selection in the DOM.
  #
  # annotation - An annotation Object to initialise.
  #
  # Examples
  #
  #   # Create a brand new annotation from the currently selected text.
  #   annotation = annotator.createAnnotation()
  #   annotation = annotator.setupAnnotation(annotation)
  #   # annotation has now been assigned the currently selected range
  #   # and a highlight appended to the DOM.
  #
  #   # Add an existing annotation that has been stored elsewere to the DOM.
  #   annotation = getStoredAnnotationWithSerializedRanges()
  #   annotation = annotator.setupAnnotation(annotation)
  #
  # Returns the initialised annotation.
  setupAnnotation: (annotation) ->
    root = @wrapper[0]
    annotation.ranges or= @selectedRanges

    normedRanges = []
    for r in annotation.ranges
      try
        normedRanges.push(Range.sniff(r).normalize(root))
      catch e
        if e instanceof Range.RangeError
          this.publish('rangeNormalizeFail', [annotation, r, e])
        else
          # Oh Javascript, why you so crap? This will lose the traceback.
          throw e

    annotation.quote      = []
    annotation.ranges     = []
    annotation.highlights = []

    for normed in normedRanges
      annotation.quote.push      $.trim(normed.text())
      annotation.ranges.push     normed.serialize(@wrapper[0], '.annotator-hl')
      $.merge annotation.highlights, this.highlightRange(normed)

    # Join all the quotes into one string.
    annotation.quote = annotation.quote.join(' / ')

    # Save the annotation data on each highlighter element.
    $(annotation.highlights).data('annotation', annotation)

    annotation

  # Public: Publishes the 'beforeAnnotationUpdated' and 'annotationUpdated'
  # events. Listeners wishing to modify an updated annotation should subscribe
  # to 'beforeAnnotationUpdated' while listeners storing annotations should
  # subscribe to 'annotationUpdated'.
  #
  # annotation - An annotation Object to update.
  #
  # Examples
  #
  #   annotation = {tags: 'apples oranges pears'}
  #   annotator.on 'beforeAnnotationUpdated', (annotation) ->
  #     # validate or modify a property.
  #     annotation.tags = annotation.tags.split(' ')
  #   annotator.updateAnnotation(annotation)
  #   # => Returns ["apples", "oranges", "pears"]
  #
  # Returns annotation Object.
  updateAnnotation: (annotation) ->
    this.publish('beforeAnnotationUpdated', [annotation])
    this.publish('annotationUpdated', [annotation])
    annotation

  # Public: Deletes the annotation by removing the highlight from the DOM.
  # Publishes the 'annotationDeleted' event on completion.
  #
  # annotation - An annotation Object to delete.
  #
  # Returns deleted annotation.
  deleteAnnotation: (annotation) ->
    if annotation.highlights?
      for h in annotation.highlights when h.parentNode?
        child = h.childNodes[0]
        $(h).replaceWith(h.childNodes)

    this.publish('annotationDeleted', [annotation])
    annotation

  # Public: Loads an Array of annotations into the @element. Breaks the task
  # into chunks of 10 annotations.
  #
  # annotations - An Array of annotation Objects.
  #
  # Examples
  #
  #   loadAnnotationsFromStore (annotations) ->
  #     annotator.loadAnnotations(annotations)
  #
  # Returns itself for chaining.
  loadAnnotations: (annotations=[]) ->
    loader = (annList=[]) =>
      now = annList.splice(0,10)

      for n in now
        this.setupAnnotation(n)

      # If there are more to do, do them after a 10ms break (for browser
      # responsiveness).
      if annList.length > 0
        setTimeout((-> loader(annList)), 10)
      else
        this.publish 'annotationsLoaded', [clone]

    clone = annotations.slice()
    loader(annotations) if annotations.length
    this

  # Public: Calls the Store#dumpAnnotations() method.
  #
  # Returns dumped annotations Array or false if Store is not loaded.
  dumpAnnotations: () ->
    if @plugins['Store']
      @plugins['Store'].dumpAnnotations()
    else
      console.warn(_t("Can't dump annotations without Store plugin."))
      return false


