define [
  'app'
  'leaflet'
  'leaflet.markercluster'
], (app, Leaflet) ->

  class MapControl
    constructor: (@el) ->
      @createMap()

    createMap: ->
      @mapFactory = new MapFactory(@el)
      @map = @mapFactory.map
      @map.on 'locationfound', @updateCurrentLocation
      @map.on 'locationfound', @setupBoundsListeners
      app.on 'map:fitmarkers', @fitBounds

      @items = []

      @markerClusterer = new L.MarkerClusterGroup
        showCoverageOnHover: false
        maxClusterRadius: 34
      .addTo(@map)

    updateCurrentLocation: (e) =>
      @currentLocation = e.latlng
      @currentLatLng = new LatLngString(e.latlng).string
      @mapFactory.updateCurrentLocationMarker(e)
      app.trigger 'locationfound'

    createMarker: (attrs) ->
      marker = new MapMarker(attrs.lat, attrs.lng, attrs.className)
      @items.push marker
      marker

    addMarker: ->
      marker = @createMarker(lat, lng, className)
      @markerClusterer.addLayer marker

    renderMarkers: ->
      @markerClusterer.addLayers(@items)

    clearMarkers: ->
      @items = []
      @markerClusterer.clearLayers()

    getDistance: (latlng) ->
      @currentLocation.distanceTo(latlng)

    fitBounds: =>
      @map.fitBounds @markerClusterer.getBounds()

    setupBoundsListeners: =>
      @map.on 'zoomend moveend', @shouldFetch
      @map.off 'locationfound', @setupBoundsListeners

    removeBoundsListeners: ->
      @map.off 'zoomend moveend', @shouldFetch

    shouldFetch: =>
      if @willFetch() and !app.searchMode
        @triggerFetch()

    willFetch: ->
      try
        !@markerClusterer.getBounds().contains @map.getBounds()
      catch error
        false

    triggerFetch: (bounds) ->
      if @shouldFetchWorld()
        @fetchWorld()
      else
        @fetchWithinBounds()

    shouldFetchWorld: ->
      bounds = @map.getBounds()
      bigLat = ((bounds.getNorth() + 90) - (bounds.getSouth() + 90)) > 10
      bigLng = ((bounds.getEast() + 180) - (bounds.getWest() + 180)) > 15
      return bigLat or bigLng

    fetchWorld: ->
      app.trigger 'map:fetchItems', "-90,-180,90,180"
      @removeBoundsListeners()

    fetchWithinBounds: ->
      bounds = @map.getBounds().pad(1)
      southWest = new LatLngString(bounds.getSouthWest()).string
      northEast = new LatLngString(bounds.getNorthEast()).string
      app.trigger 'map:fetchItems', "#{southWest},#{northEast}"

  class MapFactory
    constructor: (@el) ->
      @createMap()
      @createTiles().addTo @map

      app.on 'geoLocate', @locate
      @map.on 'locationerror', @locationError
      @locate()

      @map.on 'click', (e) ->
        app.trigger 'map:Interaction'

    createMap: ->
      @map = L.map @el,
        zoomControl        : false
        attributionControl : false
        maxZoom            : 16
        minZoom            : 2
        worldCopyJump      : true

    createTiles: ->
      L.tileLayer 'http://{s}.tiles.mapbox.com/v3/mpl.map-glvcefkt/{z}/{x}/{y}.png',
        detectRetina: true
        maxZoom: 24

    updateCurrentLocationMarker: (e) =>
      unless @currentMarker?
        @currentMarker ?= new CurrentLocationMarker e.latlng, e.accuracy
        @currentMarker.layers.addTo(@map);

      else
        @currentMarker.update e.latlng, e.accuracy

    locate: =>
      @map.locate
        setView: true

    locationError: (e) =>
      app.trigger 'locationError'
      unless @currentMarker
        @map.setView([46, -95], 2)

  class MapMarker
    constructor: (@lat, @lng, @className) ->
      return @createMarker()

    createMarker: ->
      new L.Marker [@lat, @lng],
        icon: @markerIcon()

    markerIcon: ->
      options =
        iconSize: L.point(34, 34)

      if @className?
        options['className'] = @className

      new L.DivIcon options

  class CurrentLocationMarker
    constructor: (@latlng, @accuracy) ->
      @layers = new L.LayerGroup @currentLocationLayers()

    currentLocationLayers: () ->
      radius = @accuracy / 2

      @circle = L.circle @latlng, radius,
        weight: 1

      @centerpoint = new MapMarker(@latlng.lat, @latlng.lng, 'map-current-location')

      return [@circle, @centerpoint]

    update: (@latlng, @accuracy) ->
      @circle.setLatLng @latlng
      @circle.setRadius(@accuracy / 2)
      @centerpoint.setLatLng @latlng

  class LatLngString
    constructor: (latlng, precision=1) ->
      lat = L.Util.formatNum(latlng.lat, precision)
      lng = L.Util.formatNum(latlng.lng, precision)
      @string = "#{lat},#{lng}"

  return MapControl
