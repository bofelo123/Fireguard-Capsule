import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'map_data_controller.dart';

const kMainBg = Color(0xFF07111F);
const kMapSurface = Color(0xFF0D1B2A);
const kCard = Color(0xFF13263A);
const kBorder = Color(0xFF1B3045);
const kPrimaryText = Color(0xFFF5F7FA);
const kSecondaryText = Color(0xFF8FA3B8);
const kInfo = Color(0xFF4DA3FF);

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final TextEditingController _searchCtrl = TextEditingController();

  static const LatLng botswanaCenter = LatLng(-24.6282, 25.9231);
  static const double initialZoom = 6.5;

  bool _showLayersPanel = false;
  bool _showFilterPanel = false;
  bool _showDrawer = false;
  dynamic _selectedEntity;
  bool _isCapsuleSelected = false;

  // Layers toggles
  final Map<String, bool> _layers = {
    'Fires': true,
    'Capsules': true,
    'Risk Zones': true,
    'Fire Spread': true,
    'Wind': false,
    'Protected Areas': false,
    'Roads': true,
    'Power Lines': false,
    'Water Sources': false,
  };

  // Filter toggles
  final Map<String, bool> _filters = {
    'Active': true,
    'Critical': true,
    'Contained': true,
    'Operational': true,
    'Warning': true,
    'Offline': true,
  };

  List<FireIncident> _fires = [];
  List<CapsuleDevice> _capsules = [];
  Map<String, dynamic> _metrics = {};
  DataConnectionState _connState = DataConnectionState.loading;
  LatLng? _myLocation;
  double _myAccuracy = 0;

  List<dynamic> _searchResults = [];
  StreamSubscription? _fireSub;
  StreamSubscription? _capsuleSub;
  StreamSubscription? _metricSub;
  StreamSubscription? _connSub;

  final List<Map<String, dynamic>> _botswanaPlaces = [
    {'name': 'Gaborone', 'lat': -24.6282, 'lng': 25.9231},
    {'name': 'Francistown', 'lat': -21.1702, 'lng': 27.5079},
    {'name': 'Maun', 'lat': -19.9833, 'lng': 23.4167},
    {'name': 'Kasane', 'lat': -17.8037, 'lng': 25.1535},
    {'name': 'Ghanzi', 'lat': -21.6985, 'lng': 21.6487},
    {'name': 'Serowe', 'lat': -22.3977, 'lng': 26.7122},
    {'name': 'Kanye', 'lat': -24.9628, 'lng': 25.3327},
    {
      'name': 'Central Kalahari Game Reserve',
      'lat': -21.5,
      'lng': 23.5
    },
    {'name': 'Chobe National Park', 'lat': -18.5, 'lng': 24.8},
  ];

  @override
  void initState() {
    super.initState();

    final ctrl = Provider.of<MapDataController>(
      context,
      listen: false,
    );

    _fireSub = ctrl.firesStream.listen(
      (d) => setState(() => _fires = d),
    );

    _capsuleSub = ctrl.capsulesStream.listen(
      (d) => setState(() => _capsules = d),
    );

    _metricSub = ctrl.metricsStream.listen(
      (d) => setState(() => _metrics = d),
    );

    _connSub = ctrl.connectionStream.listen(
      (s) => setState(() => _connState = s),
    );

    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _fireSub?.cancel();
    _capsuleSub?.cancel();
    _metricSub?.cancel();
    _connSub?.cancel();

    _searchCtrl.dispose();
    _mapController.dispose();

    super.dispose();
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text.trim().toLowerCase();

    if (q.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    List<dynamic> results = [];

    // Coordinates: -24.6282,25.9231
    final coordReg =
        RegExp(r'^(-?\d+\.?\d*)\s*[, ]\s*(-?\d+\.?\d*)$');

    final coordMatch = coordReg.firstMatch(q);

    if (coordMatch != null) {
      results.add({
        'type': 'coord',
        'lat': double.parse(coordMatch.group(1)!),
        'lng': double.parse(coordMatch.group(2)!),
      });
    }

    for (var f in _fires) {
      if (f.id.toLowerCase().contains(q)) {
        results.add(f);
      }
    }

    for (var c in _capsules) {
      if (c.id.toLowerCase().contains(q)) {
        results.add(c);
      }
    }

    for (var p in _botswanaPlaces) {
      if ((p['name'] as String).toLowerCase().contains(q)) {
        results.add(p);
      }
    }

    setState(() {
      _searchResults = results.take(8).toList();
    });
  }

  Future<void> _goToMyLocation() async {
    try {
      bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _showSnack('Location services disabled');
        return;
      }

      LocationPermission perm =
          await Geolocator.checkPermission();

      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }

      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        _showSnack('Location permission denied');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final ll = LatLng(
        pos.latitude,
        pos.longitude,
      );

      setState(() {
        _myLocation = ll;
        _myAccuracy = pos.accuracy;
      });

      _mapController.move(ll, 12);
    } catch (e) {
      _showSnack('Location unavailable');
    }
  }

  void _showSnack(String m) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m),
        backgroundColor: kCard,
      ),
    );
  }

  Color _fireColor(FireSeverity s) {
    switch (s) {
      case FireSeverity.low:
        return Colors.orange;

      case FireSeverity.medium:
        return const Color(0xFFFFB547);

      case FireSeverity.high:
        return const Color(0xFFFF4D3D);

      case FireSeverity.critical:
        return const Color(0xFFD00000);
    }
  }

  Color _capsuleColor(CapsuleStatus s) {
    switch (s) {
      case CapsuleStatus.operational:
        return const Color(0xFF25C281);

      case CapsuleStatus.warning:
        return const Color(0xFFFFB547);

      case CapsuleStatus.critical:
        return const Color(0xFFFF4D3D);

      case CapsuleStatus.offline:
        return const Color(0xFF8FA3B8);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kMainBg,
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _buildMapArea(),
                ),
                _buildBottomMetrics(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 240,
      color: const Color(0xFF0B1A2B),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  width: 32,
                  height: 32,
                  errorBuilder: (_, __, ___) => Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: kInfo,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.local_fire_department,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'FIREGUARD',
                  style: TextStyle(
                    color: kPrimaryText,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _sideItem(
            Icons.dashboard_outlined,
            'Overview',
            false,
          ),
          _sideItem(
            Icons.map_outlined,
            'Live Map',
            true,
          ),
          _sideItem(
            Icons.warning_amber_outlined,
            'Incidents',
            false,
          ),
          _sideItem(
            Icons.satellite_alt_outlined,
            'Capsules',
            false,
          ),
          _sideItem(
            Icons.analytics_outlined,
            'Risk Intelligence',
            false,
          ),
          _sideItem(
            Icons.notifications_outlined,
            'Alerts',
            false,
          ),
          const Divider(
            color: kBorder,
            height: 32,
          ),
          _sideItem(
            Icons.health_and_safety_outlined,
            'System Health',
            false,
          ),
          _sideItem(
            Icons.description_outlined,
            'Reports',
            false,
          ),
          _sideItem(
            Icons.settings_outlined,
            'Settings',
            false,
          ),
        ],
      ),
    );
  }

  Widget _sideItem(
    IconData icon,
    String label,
    bool selected,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: selected ? kCard : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: selected ? kBorder : Colors.transparent,
        ),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          icon,
          color: selected ? kInfo : kSecondaryText,
          size: 20,
        ),
        title: Text(
          label,
          style: TextStyle(
            color:
                selected ? kPrimaryText : kSecondaryText,
            fontSize: 13,
            fontWeight:
                selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        onTap: () {
          if (label == 'Overview') {
            Navigator.pushReplacementNamed(
              context,
              '/dashboard',
            );
          } else if (label == 'Live Map') {
            Navigator.pushReplacementNamed(
              context,
              '/map',
            );
          }
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 72,
      color: kMainBg,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const SizedBox(width: 4),
          Expanded(
            child: Row(
              children: [
                const Flexible(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Text(
                        'Live Wildfire Map',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: kPrimaryText,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Real-time wildfire monitoring',
                        style: TextStyle(
                          fontSize: 12,
                          color: kSecondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Container(
              constraints: const BoxConstraints(
                maxWidth: 320,
                minWidth: 180,
              ),
              height: 40,
              decoration: BoxDecoration(
                color: kMapSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kBorder),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(
                  color: kPrimaryText,
                  fontSize: 13,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText:
                      'Search fire, capsule, location...',
                  hintStyle: TextStyle(
                    color: kSecondaryText,
                    fontSize: 13,
                  ),
                  icon: Icon(
                    Icons.search,
                    color: kSecondaryText,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _liveChip(),
          const SizedBox(width: 8),
          _iconBtn(
            Icons.notifications_none,
            () {},
          ),
          const SizedBox(width: 8),
          _iconBtn(
            Icons.person_outline,
            () {},
          ),
        ],
      ),
    );
  }

  Widget _liveChip() {
    String text;
    Color dot;

    switch (_connState) {
      case DataConnectionState.live:
        text = '● LIVE';
        dot = Colors.greenAccent;
        break;

      case DataConnectionState.loading:
        text = '○ Fetching live data...';
        dot = kSecondaryText;
        break;

      case DataConnectionState.offline:
        text = '● OFFLINE';
        dot = Colors.grey;
        break;

      case DataConnectionState.empty:
        text = 'No active incidents';
        dot = Colors.orange;
        break;

      case DataConnectionState.stale:
        text = '● STALE DATA';
        dot = Colors.amber;
        break;

      case DataConnectionState.error:
        text = '● ERROR';
        dot = Colors.redAccent;
        break;
    }

    return Container(
      height: 40,
      padding:
          const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _connState ==
                DataConnectionState.live
            ? const Color(0xFF1A2E1A)
            : kCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: [
          Text(
            text,
            style: TextStyle(
              color: _connState ==
                      DataConnectionState.live
                  ? Colors.greenAccent
                  : kSecondaryText,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(
    IconData i,
    VoidCallback cb,
  ) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: kMapSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kBorder),
      ),
      child: IconButton(
        icon: Icon(
          i,
          color: kPrimaryText,
          size: 20,
        ),
        onPressed: cb,
      ),
    );
  }

  Widget _buildMapArea() {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: botswanaCenter,
              initialZoom: initialZoom,
              minZoom: 3,
              maxZoom: 18,
              onTap: (_, __) {
                setState(() {
                  _showDrawer = false;
                  _showLayersPanel = false;
                  _searchResults = [];
                });
              },
            ),
            children: [
              // BRIGHT BASE MAP - independent of data loading
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName:
                    'com.fireguard.app',
                maxZoom: 19,
              ),

              // Risk zones layer
              if (_layers['Risk Zones']! &&
                  _filters['Active']!)
                PolygonLayer(
                  polygons: <Polygon<Object>>[],
                ),

              // Protected areas
              if (_layers['Protected Areas']!)
                PolygonLayer(
                  polygons:
                      _buildProtectedAreaPolygons(),
                ),

              // Fire perimeter - solid boundary
              if (_layers['Fire Spread']!)
                PolygonLayer(
                  polygons: _buildFirePerimeters(),
                ),

              // Predicted spread - transparent projected
              if (_layers['Fire Spread']!)
                PolygonLayer(
                  polygons: _buildPredictedSpread(),
                ),

              // My location accuracy circle
              if (_myLocation != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _myLocation!,
                      radius: _myAccuracy,
                      useRadiusInMeter: true,
                      color:
                          Colors.blue.withOpacity(0.15),
                      borderColor: Colors.blue,
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),

              // Fire markers + capsule markers + current location dot
              MarkerLayer(
                markers: [
                  ..._buildFireMarkers(),
                  ..._buildCapsuleMarkers(),
                  if (_myLocation != null)
                    Marker(
                      point: _myLocation!,
                      width: 24,
                      height: 24,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.blue,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 8,
                              color: Colors.blue
                                  .withOpacity(0.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

              // Attribution - REQUIRED
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    '© OpenStreetMap contributors',
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),

          // Map Search results dropdown
          if (_searchResults.isNotEmpty)
            Positioned(
              left: 16,
              top: 16,
              child: _searchResultsPanel(),
            ),

          if (_searchResults.isEmpty)
            Positioned(
              left: 16,
              top: 16,
              child: _mapSearchPlaceholder(),
            ),

          // Top-right controls INSIDE map stack
          Positioned(
            top: 20,
            right: 20,
            child: _mapControls(),
          ),

          // Layers panel
          if (_showLayersPanel)
            Positioned(
              top: 80,
              right: 20,
              child: _layersPanel(),
            ),

          // Filter panel
          if (_showFilterPanel)
            Positioned(
              top: 16,
              left: 320,
              child: _filterPanel(),
            ),

          // Legend bottom-left
          Positioned(
            left: 16,
            bottom: 16,
            child: _legend(),
          ),

          // Info drawer
          if (_showDrawer)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: _infoDrawer(),
            ),
        ],
      ),
    );
  }

  Widget _mapSearchPlaceholder() {
    return Row(
      children: [
        Container(
          width: 280,
          height: 40,
          decoration: BoxDecoration(
            color: kCard.withOpacity(0.95),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: kBorder),
          ),
          padding:
              const EdgeInsets.symmetric(horizontal: 12),
          child: const Row(
            children: [
              Icon(
                Icons.search,
                color: kSecondaryText,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Search fire, capsule, location...',
                style: TextStyle(
                  color: kSecondaryText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: () => setState(
            () => _showFilterPanel =
                !_showFilterPanel,
          ),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kBorder),
            ),
            child: const Icon(
              Icons.filter_list,
              color: kPrimaryText,
            ),
          ),
        ),
      ],
    );
  }

  Widget _searchResultsPanel() {
    return Material(
      color: kCard,
      borderRadius: BorderRadius.circular(10),
      elevation: 8,
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: kBorder),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            ..._searchResults.map((r) {
              String title;
              String subtitle;
              IconData icon;

              if (r is FireIncident) {
                title = r.id;
                subtitle = r.severity.name;
                icon = Icons.local_fire_department;
              } else if (r is CapsuleDevice) {
                title = r.id;
                subtitle = r.status.name;
                icon = Icons.satellite_alt;
              } else if (r is Map &&
                  r['type'] == 'coord') {
                title =
                    '${r['lat']}, ${r['lng']}';
                subtitle = 'Coordinates';
                icon = Icons.my_location;
              } else {
                title = r['name'];
                subtitle = 'Location';
                icon = Icons.place;
              }

              return ListTile(
                dense: true,
                leading: Icon(
                  icon,
                  color: kInfo,
                  size: 18,
                ),
                title: Text(
                  title,
                  style: const TextStyle(
                    color: kPrimaryText,
                    fontSize: 13,
                  ),
                ),
                subtitle: Text(
                  subtitle,
                  style: const TextStyle(
                    color: kSecondaryText,
                    fontSize: 11,
                  ),
                ),
                onTap: () {
                  if (r is FireIncident) {
                    _mapController.move(
                      LatLng(r.lat, r.lng),
                      11,
                    );

                    setState(() {
                      _selectedEntity = r;
                      _isCapsuleSelected = false;
                      _showDrawer = true;
                      _searchResults = [];
                      _searchCtrl.clear();
                    });
                  } else if (r is CapsuleDevice) {
                    _mapController.move(
                      LatLng(r.lat, r.lng),
                      12,
                    );

                    setState(() {
                      _selectedEntity = r;
                      _isCapsuleSelected = true;
                      _showDrawer = true;
                      _searchResults = [];
                      _searchCtrl.clear();
                    });
                  } else if (r is Map &&
                      r['type'] == 'coord') {
                    _mapController.move(
                      LatLng(
                        r['lat'],
                        r['lng'],
                      ),
                      12,
                    );

                    setState(
                      () => _searchResults = [],
                    );
                  } else {
                    _mapController.move(
                      LatLng(
                        r['lat'],
                        r['lng'],
                      ),
                      10,
                    );

                    setState(
                      () => _searchResults = [],
                    );
                  }
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _mapControls() {
    Widget btn(
      IconData ic,
      String tip,
      VoidCallback cb,
    ) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Tooltip(
          message: tip,
          child: InkWell(
            onTap: cb,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: kCard,
                borderRadius:
                    BorderRadius.circular(8),
                border: Border.all(
                  color: kBorder,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black.withOpacity(0.3),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Icon(
                ic,
                color: kPrimaryText,
                size: 20,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        btn(
          Icons.add,
          'Zoom in',
          () => _mapController.move(
            _mapController.camera.center,
            _mapController.camera.zoom + 1,
          ),
        ),
        btn(
          Icons.remove,
          'Zoom out',
          () => _mapController.move(
            _mapController.camera.center,
            _mapController.camera.zoom - 1,
          ),
        ),
        btn(
          Icons.my_location,
          'My location',
          _goToMyLocation,
        ),
        btn(
          Icons.layers_outlined,
          'Layers',
          () => setState(
            () => _showLayersPanel =
                !_showLayersPanel,
          ),
        ),
        btn(
          Icons.fullscreen,
          'Fullscreen',
          () {},
        ),
      ],
    );
  }

  Widget _layersPanel() {
    return Material(
      color: kCard,
      borderRadius: BorderRadius.circular(10),
      elevation: 8,
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: kBorder),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'MAP LAYERS',
              style: TextStyle(
                color: kPrimaryText,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            ..._layers.keys.map(
              (k) => CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: _layers[k],
                title: Text(
                  k,
                  style: const TextStyle(
                    color: kPrimaryText,
                    fontSize: 12,
                  ),
                ),
                activeColor: kInfo,
                onChanged: (v) => setState(
                  () => _layers[k] = v!,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterPanel() {
    return Material(
      color: kCard,
      borderRadius: BorderRadius.circular(10),
      elevation: 8,
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: kBorder),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'FILTER MAP',
                  style: TextStyle(
                    color: kPrimaryText,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: kSecondaryText,
                    size: 16,
                  ),
                  onPressed: () => setState(
                    () => _showFilterPanel = false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'FIRES',
              style: TextStyle(
                color: kSecondaryText,
                fontSize: 10,
                letterSpacing: 1,
              ),
            ),
            ...['Active', 'Critical', 'Contained']
                .map(
              (e) => CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: _filters[e],
                title: Text(
                  e,
                  style: const TextStyle(
                    color: kPrimaryText,
                    fontSize: 12,
                  ),
                ),
                onChanged: (v) => setState(
                  () => _filters[e] = v!,
                ),
              ),
            ),
            const Text(
              'CAPSULES',
              style: TextStyle(
                color: kSecondaryText,
                fontSize: 10,
                letterSpacing: 1,
              ),
            ),
            ...['Operational', 'Warning', 'Offline']
                .map(
              (e) => CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: _filters[e],
                title: Text(
                  e,
                  style: const TextStyle(
                    color: kPrimaryText,
                    fontSize: 12,
                  ),
                ),
                onChanged: (v) => setState(
                  () => _filters[e] = v!,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => setState(
                () => _showFilterPanel = false,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kInfo,
              ),
              child: const Text(
                'Apply',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legend() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: kMainBg.withOpacity(0.85),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kBorder),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 4,
        children: [
          _legDot(
            const Color(0xFF25C281),
            'Operational',
          ),
          _legDot(
            const Color(0xFFFFB547),
            'Warning',
          ),
          _legDot(
            const Color(0xFFFF4D3D),
            'Fire',
          ),
          _legDot(
            const Color(0xFF8FA3B8),
            'Offline',
          ),
        ],
      ),
    );
  }

  Widget _legDot(
    Color c,
    String l,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: c,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          l,
          style: const TextStyle(
            color: kSecondaryText,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  // MARKER BUILDERS - REAL DATA ONLY
  List<Marker> _buildFireMarkers() {
    if (!_layers['Fires']!) {
      return [];
    }

    return _fires
        .where((f) {
          if (f.severity ==
                  FireSeverity.critical &&
              _filters['Critical'] == false) {
            return false;
          }

          return true;
        })
        .map((f) {
          return Marker(
            point: LatLng(f.lat, f.lng),
            width: 36,
            height: 36,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedEntity = f;
                  _isCapsuleSelected = false;
                  _showDrawer = true;
                });

                _mapController.move(
                  LatLng(f.lat, f.lng),
                  11,
                );
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (f.severity ==
                      FireSeverity.critical)
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _fireColor(
                          f.severity,
                        ).withOpacity(0.25),
                      ),
                    ),
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: _fireColor(
                        f.severity,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _fireColor(
                            f.severity,
                          ).withOpacity(0.6),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.local_fire_department,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        })
        .toList();
  }

  List<Marker> _buildCapsuleMarkers() {
    if (!_layers['Capsules']!) {
      return [];
    }

    return _capsules
        .where((c) {
          if (c.status ==
                  CapsuleStatus.offline &&
              _filters['Offline'] == false) {
            return false;
          }

          if (c.status ==
                  CapsuleStatus.operational &&
              _filters['Operational'] == false) {
            return false;
          }

          if (c.status ==
                  CapsuleStatus.warning &&
              _filters['Warning'] == false) {
            return false;
          }

          return true;
        })
        .map((c) {
          return Marker(
            point: LatLng(c.lat, c.lng),
            width: 28,
            height: 28,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedEntity = c;
                  _isCapsuleSelected = true;
                  _showDrawer = true;
                });

                _mapController.move(
                  LatLng(c.lat, c.lng),
                  12,
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: _capsuleColor(
                    c.status,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.satellite_alt,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
          );
        })
        .toList();
  }

  // FIXED: Explicit Polygon<Object> generic type.
  List<Polygon<Object>> _buildFirePerimeters() {
    return _fires
        .where(
          (f) =>
              f.perimeter != null &&
              f.perimeter!.isNotEmpty,
        )
        .map<Polygon<Object>>((f) {
          return Polygon<Object>(
            points: f.perimeter!
                .map(
                  (p) => LatLng(
                    p.lat,
                    p.lng,
                  ),
                )
                .toList(),
            color: Colors.red.withOpacity(0.15),
            borderColor: Colors.red,
            borderStrokeWidth: 2,
          );
        })
        .toList();
  }

  // FIXED: Explicit Polygon<Object> generic type.
  List<Polygon<Object>> _buildPredictedSpread() {
    return _fires
        .where(
          (f) =>
              f.predictedSpread != null &&
              f.predictedSpread!.isNotEmpty,
        )
        .map<Polygon<Object>>((f) {
          return Polygon<Object>(
            points: f.predictedSpread!
                .map(
                  (p) => LatLng(
                    p.lat,
                    p.lng,
                  ),
                )
                .toList(),
            color: Colors.orange.withOpacity(0.12),
            borderColor: Colors.orange,
            borderStrokeWidth: 2,
            pattern: StrokePattern.dashed(
              segments: [8, 6],
            ),
          );
        })
        .toList();
  }

  // FIXED: Explicit Polygon<Object> generic type.
  List<Polygon<Object>> _buildProtectedAreaPolygons() {
    // Replace with real protected area polygons from backend
    return <Polygon<Object>>[];
  }

  Widget _infoDrawer() {
    final isFire = _selectedEntity is FireIncident;
    final isCapsule =
        _selectedEntity is CapsuleDevice;

    return Container(
      width: 360,
      constraints:
          const BoxConstraints(maxWidth: 400),
      margin: const EdgeInsets.only(
        top: 72,
        bottom: 0,
        right: 0,
      ),
      decoration: const BoxDecoration(
        color: kCard,
        border: Border(
          left: BorderSide(
            color: kBorder,
          ),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isFire
                      ? 'FIRE DETAILS'
                      : isCapsule
                          ? 'CAPSULE DETAILS'
                          : 'DETAILS',
                  style: const TextStyle(
                    color: kPrimaryText,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: kSecondaryText,
                  ),
                  onPressed: () => setState(
                    () => _showDrawer = false,
                  ),
                ),
              ],
            ),
          ),
          const Divider(
            color: kBorder,
            height: 1,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: isFire
                  ? _fireDrawerContent(
                      _selectedEntity
                          as FireIncident,
                    )
                  : isCapsule
                      ? _capsuleDrawerContent(
                          _selectedEntity
                              as CapsuleDevice,
                        )
                      : const Text(
                          '—',
                          style: TextStyle(
                            color: kSecondaryText,
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fireDrawerContent(
    FireIncident f,
  ) =>
      Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _detailRow(
            'FIRE ID',
            f.id,
          ),
          _detailRow(
            'Severity',
            f.severity.name.toUpperCase(),
          ),
          _detailRow(
            'Location',
            '${f.lat.toStringAsFixed(4)}, ${f.lng.toStringAsFixed(4)}',
          ),
          _detailRow(
            'Detected time',
            f.detectedAt?.toString() ?? '—',
          ),
          _detailRow(
            'Fire area',
            f.areaHa != null
                ? '${f.areaHa} ha'
                : '—',
          ),
          _detailRow(
            'Temperature',
            f.temperature != null
                ? '${f.temperature}°C'
                : '—',
          ),
          _detailRow(
            'Humidity',
            f.humidity != null
                ? '${f.humidity}%'
                : '—',
          ),
          _detailRow(
            'Wind',
            f.windSpeed != null
                ? '${f.windSpeed} km/h ${f.windDir ?? ''}'
                : '—',
          ),
          _detailRow(
            'Spread direction',
            f.spreadDir ?? '—',
          ),
          _detailRow(
            'Last updated',
            f.lastUpdated?.toString() ?? '—',
          ),
        ],
      );

  Widget _capsuleDrawerContent(
    CapsuleDevice c,
  ) =>
      Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _detailRow(
            'Capsule ID',
            c.id,
          ),
          _detailRow(
            'Status',
            c.status.name,
          ),
          _detailRow(
            'GPS coordinates',
            '${c.lat.toStringAsFixed(5)}, ${c.lng.toStringAsFixed(5)}',
          ),
          _detailRow(
            'Battery',
            c.battery != null
                ? '${c.battery}%'
                : '—',
          ),
          _detailRow(
            'Temperature',
            c.temperature != null
                ? '${c.temperature}°C'
                : '—',
          ),
          _detailRow(
            'Network',
            c.network ?? '—',
          ),
          _detailRow(
            'Solar status',
            c.solarStatus ?? '—',
          ),
          _detailRow(
            'Last communication',
            c.lastComm?.toString() ?? '—',
          ),
        ],
      );

  Widget _detailRow(
    String label,
    String value,
  ) =>
      Padding(
        padding:
            const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: kSecondaryText,
                fontSize: 10,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: kPrimaryText,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );

  Widget _buildBottomMetrics() {
    return Container(
      height: 64,
      color: kMapSurface,
      padding:
          const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _metric(
            'Active Fires',
            _metrics['activeFires']?.toString() ??
                '—',
          ),
          _metric(
            'Capsules Online',
            _metrics['capsulesOnline']?.toString() ??
                '—',
          ),
          _metric(
            'Temperature',
            _metrics['temperature'] != null
                ? "${_metrics['temperature']}°C"
                : '—',
          ),
          _metric(
            'Wind',
            _metrics['wind'] != null
                ? "${_metrics['wind']} km/h"
                : '—',
          ),
          _metric(
            'Network',
            _metrics['network'] != null
                ? "${_metrics['network']}%"
                : '—',
          ),
          _metric(
            'Last Updated',
            _metrics['lastUpdated']?.toString() ??
                '—',
          ),
        ],
      ),
    );
  }

  Widget _metric(
    String label,
    String value,
  ) =>
      Expanded(
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: kPrimaryText,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: kSecondaryText,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
}