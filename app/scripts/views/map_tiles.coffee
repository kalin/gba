define [
  'app'
  'lib/map_control'
], (app, MapControl) ->
  MapView = {}

  class MapTiles extends Backbone.Layout
    className: 'tiles'

    beforeRender: ->
      @markerIcon = new L.DivIcon
        className: 'map-marker'

      @listenTo @collection,
        'refilter'     : @resetMarkers
        'reset'        : @resetMarkers
        'add'          : @addMarker
        'selectResult' : @focusMarker
        'remove'       : @removeMarker

    afterRender: ->
      @mapControl = new MapControl(@el)
      app.mapControl = @mapControl

    resetMarkers: ->
      @mapControl.clearMarkers()
      @addMarkers()

    addMarkers: ->
      @collection.filteredModels().each (item) =>
        @addMarker(item)

      @collection.trigger 'markersAdded'

      return this

    addMarker: (item) ->
      return unless _.contains @collection.filteredModels().value(), item

      lat = item.get 'lat'
      lng = item.get 'lng'

      if lat? and lng?
        marker = @mapControl.addMarker(lat, lng, item.mapMarkerClass()).on 'click', (e) =>
          @clickMarker(e, item)

        # let the model know that it has a marker.
        item.trigger 'addMarker', marker

      return this

    clickMarker: (e, item) =>
      item.trigger('mapSelect', item)

    focusMarker: (item) =>
      @mapControl.map.panTo item.marker.getLatLng()

    removeMarker: (item) =>
      @mapControl.items.removeLayer(item.marker)

  return MapTiles
