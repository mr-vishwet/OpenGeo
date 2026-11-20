// OpenGeo MapLibre adapter.
//
// Exposes one class, window.OpenGeoMap, so the Flutter side only ever calls
// plain methods with strings/numbers instead of walking the maplibre API
// through JS interop. Loaded as a module so it can import the ESM bundle.
import * as maplibregl from './maplibre-gl.js';

const DEM_TILES = 'https://s3.amazonaws.com/elevation-tiles-prod/terrarium/{z}/{x}/{y}.png';
const DEM_ATTRIBUTION = 'Elevation: AWS Terrain Tiles (Mapzen)';

window.maplibregl = maplibregl;

class OpenGeoMap {
  constructor(container, config, callbacks) {
    this.opts = config || {};
    this.cb = callbacks || {};
    this._loaded = false;
    this._pending = { markers: null, route: null, routeColor: '#1A73E8' };
    this._markers = [];

    let map;
    try {
      map = new maplibregl.Map({
        container,
        style: this.opts.styleIsUrl ? this.opts.style : JSON.parse(this.opts.style),
        center: [this.opts.lng || 0, this.opts.lat || 0],
        zoom: this.opts.zoom == null ? 12 : this.opts.zoom,
        pitch: this.opts.pitch || 0,
        bearing: 0,
        attributionControl: false,
        // One screenful of 256px tiles is ~40 tiles; 256 bounds the cache at
        // roughly the same 64 MB budget the raster fallback uses.
        maxTileCacheSize: 256,
        maxTileCacheZoomLevels: 2,
        cancelPendingTileRequestsWhileZooming: true,
        fadeDuration: 150,
        trackResize: true,
      });
    } catch (err) {
      // Async so the Dart handle exists before the failure arrives.
      const msg = 'webgl: ' + ((err && err.message) || err);
      setTimeout(() => this.cb.onError && this.cb.onError(msg), 0);
      return;
    }
    this.map = map;

    map.addControl(
      new maplibregl.AttributionControl({
        customAttribution: this.opts.attribution || '',
        compact: true,
      }),
      'bottom-right'
    );
    // No NavigationControl: the Flutter shell already owns locate/layers/zoom
    // buttons in the same corner, and GL controls would sit above them.

    map.on('load', () => this._onReady());
    // setStyle() does not re-fire 'load', so treat every 'idle' after a style
    // change as "style is ready" and re-apply our layers.
    map.on('idle', () => {
      if (!this._loaded) this._onReady();
    });
    map.on('error', (e) => {
      // Only fatal before the first successful load (WebGL/style failures);
      // stray tile errors afterwards must not tear the map down.
      if (!this._loaded && this.cb.onError) {
        const msg = (e && e.error && e.error.message) || 'map error';
        this.cb.onError(String(msg));
      }
    });
  }

  _onReady() {
    if (this._loaded || !this.map) return;
    this._loaded = true;
    this._applyTerrain();
    this._applyBuildings();
    this._applyRoute();
    this._applyMarkers();
    this.cb.onLoad && this.cb.onLoad();
  }

  _applyTerrain() {
    const map = this.map;
    if (!map || !this._loaded) return;
    if (this.opts.relief) {
      if (!map.getSource('og-dem')) {
        map.addSource('og-dem', {
          type: 'raster-dem',
          tiles: [DEM_TILES],
          tileSize: 256,
          encoding: 'terrarium',
          maxzoom: 13,
          attribution: DEM_ATTRIBUTION,
        });
      }
      if (!map.getTerrain()) map.setTerrain({ source: 'og-dem', exaggeration: 1.35 });
    } else if (map.getTerrain()) {
      map.setTerrain(null);
    }
  }

  _applyBuildings() {
    const map = this.map;
    if (!map || !this._loaded) return;
    if (map.getLayer('building-3d')) {
      map.setLayoutProperty('building-3d', 'visibility', this.opts.buildings ? 'visible' : 'none');
    }
  }

  _applyMarkers() {
    const map = this.map;
    if (!map || !this._loaded) return;
    this._markers.forEach((m) => m.remove());
    this._markers = [];
    const list = this._pending.markers || [];
    for (let i = 0; i < list.length; i++) {
      const m = list[i];
      const el = document.createElement('div');
      el.className = 'og-pin' + (m.highlighted ? ' og-pin-hl' : '');
      el.style.background = m.color;
      el.title = m.label || '';
      el.addEventListener('click', (e) => {
        e.stopPropagation();
        this.cb.onMarkerTap && this.cb.onMarkerTap(i);
      });
      this._markers.push(
        new maplibregl.Marker({ element: el, anchor: 'bottom' })
          .setLngLat([m.lng, m.lat])
          .addTo(map)
      );
    }
  }

  _applyRoute() {
    const map = this.map;
    if (!map || !this._loaded) return;
    const coords = this._pending.route || [];
    const color = this._pending.routeColor || '#1A73E8';
    const line = { type: 'LineString', coordinates: coords };
    const ends = {
      type: 'FeatureCollection',
      features: coords.length
        ? [
            { type: 'Feature', geometry: { type: 'Point', coordinates: coords[0] }, properties: {} },
            { type: 'Feature', geometry: { type: 'Point', coordinates: coords[coords.length - 1] }, properties: {} },
          ]
        : [],
    };

    if (!map.getSource('og-route')) {
      if (coords.length < 2) return;
      map.addSource('og-route', { type: 'geojson', data: line });
      map.addLayer({
        id: 'og-route-halo',
        type: 'line',
        source: 'og-route',
        layout: { 'line-cap': 'round', 'line-join': 'round' },
        paint: { 'line-color': '#ffffff', 'line-width': 9, 'line-opacity': 0.85 },
      });
      map.addLayer({
        id: 'og-route-line',
        type: 'line',
        source: 'og-route',
        layout: { 'line-cap': 'round', 'line-join': 'round' },
        paint: { 'line-color': color, 'line-width': 5 },
      });
      map.addSource('og-route-ends', { type: 'geojson', data: ends });
      map.addLayer({
        id: 'og-route-ends',
        type: 'circle',
        source: 'og-route-ends',
        paint: {
          'circle-radius': 6,
          'circle-color': color,
          'circle-stroke-width': 2.5,
          'circle-stroke-color': '#ffffff',
        },
      });
    } else {
      map.getSource('og-route').setData(line);
      map.getSource('og-route-ends').setData(ends);
      map.setPaintProperty('og-route-line', 'line-color', color);
      map.setPaintProperty('og-route-ends', 'circle-color', color);
    }
  }

  // ---- called from Dart -------------------------------------------------

  setStyle(json, isUrl) {
    if (!this.map) return;
    this._loaded = false;
    this.map.setStyle(isUrl ? json : JSON.parse(json));
  }

  setRelief(on) {
    this.opts.relief = !!on;
    this._applyTerrain();
  }

  setBuildings(on) {
    this.opts.buildings = !!on;
    this._applyBuildings();
  }

  setPitch(deg) {
    if (!this.map) return;
    this.map.easeTo({ pitch: deg || 0, duration: 600 });
  }

  setMarkers(json) {
    this._pending.markers = JSON.parse(json || '[]');
    this._applyMarkers();
  }

  setRoute(json, color) {
    this._pending.route = JSON.parse(json || '[]');
    this._pending.routeColor = color || '#1A73E8';
    this._applyRoute();
  }

  recenter(lng, lat) {
    if (!this.map) return;
    this.map.easeTo({ center: [lng, lat], duration: 500 });
  }

  zoomIn() {
    if (this.map) this.map.zoomIn({ duration: 250 });
  }

  zoomOut() {
    if (this.map) this.map.zoomOut({ duration: 250 });
  }

  resize() {
    if (this.map) this.map.resize();
  }

  destroy() {
    if (this.map) {
      this.map.remove();
      this.map = null;
    }
  }
}

window.OpenGeoMap = OpenGeoMap;

// Single entry point for Dart: config travels as JSON, callbacks as functions.
window.ogCreateMap = (container, configJson, onLoad, onError, onMarkerTap) => {
  let config;
  try {
    config = JSON.parse(configJson);
  } catch (err) {
    onError && setTimeout(() => onError('bad config: ' + err.message), 0);
    return null;
  }
  return new OpenGeoMap(container, config, { onLoad, onError, onMarkerTap });
};

