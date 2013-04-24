define [
  'app'
], (app) ->

  class ItemsView extends Backbone.Layout
    initialize: ->
      @listenTo @collection,
        'markersAdded'     : @addItems
        'mapSelect'        : @selectItem
        'searchSuccessful' : @showSearchResults

    addItems: (collection, render) =>
      @collection.each (item) =>
        @insertView new Item
          id: "item-#{item.id}"
          className: "item"
          model: item

      unless render is false
        @render()

    selectItem: (item) ->
      selectedItem = @getView
        model: item

      if @currentView is selectedItem
        @hideItems();
      else
        @currentView = selectedItem
        @showItems();

    hideItems: ->
      @$el.parent().addClass('hidden')
      @currentView = null

    showItems: ->
      @currentView.$el.siblings()
        .removeClass('current')
        .end()
        .addClass('current')

        @$el.parent().removeClass('hidden')

    showSearchResults: =>
      console.log 'should show search results now.'

  class Item extends Backbone.Layout
    template: 'item'

    events:
      'click header': 'openItem'
      'click .arrow': 'closeItem'

    initialize: ->
      @listenTo @model, 'mapSelect', @changeDistance

    openItem: (event) =>
      return if @openView?

      @openView = @insertView(new ItemDetails
        model: @model
        tagName: 'article'
      ).render().view
      @model.trigger 'open', @model
      @openView.$el.height(
        $('#main').height() - @$el.find('header').innerHeight()
      )

      event.stopImmediatePropagation()

    closeItem: (event) =>
      return unless @openView?

      @model.trigger 'close', @model
      @removeView @openView
      delete @openView

      event.stopImmediatePropagation()

    serialize: ->
      @model.toJSON()

    changeDistance: () =>
      @$el.find('.distance')
      .html @model.get('distance')

  class ItemDetails extends Backbone.Layout
    className: 'item-details'
    template: 'item_details'

    serialize: ->
      @model.toJSON()

  return ItemsView
