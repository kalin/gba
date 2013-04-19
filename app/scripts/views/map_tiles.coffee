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
        'reset': @addMarkers
        'add': @addMarker
        'fetch': ->
          # TODO something with fetched locations
          console.log 'getting locations'

    afterRender: ->
      app.mapControl = new MapControl(@el)

    addMarkers: ->
      @collection.each (item) =>
        @addMarker(item)

      @collection.trigger 'markersAdded'

      return this

    addMarker: (item) ->
      lat = item.get 'lat'
      lng = item.get 'lng'

      if lat? and lng?
        marker = app.mapControl.addMarker(lat, lng).on 'click', (e) =>
          @clickMarker(e, item)

        # let the model know that it has a marker.
        item.trigger 'addMarker', marker

      else
        console.count("noLatLng")

      return this

    clickMarker: (e, item) =>
      item.trigger('mapSelect', item)

  return MapTiles