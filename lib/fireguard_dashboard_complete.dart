import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// === NAVIGATION ADDED - DO NOT REMOVE ===
import 'fireguard_capsule_detail.dart'; // <- make sure file name matches your detail file
// ========================================

// ==================== REAL-DATA MODELS ====================

enum AlertSeverity { critical, warning, info }

class FireIncidentGIS {
  final String id;
  final LatLng position;
  final AlertSeverity severity;
  final String title;
  final DateTime detectionTime;
  final String status;

  FireIncidentGIS({
    required this.id,
    required this.position,
    required this.severity,
    required this.title,
    required this.detectionTime,
    required this.status,
  });

  factory FireIncidentGIS.fromJson(Map<String, dynamic> j) {
    final severityText = j['severity']?.toString();
    final severity = AlertSeverity.values.firstWhere(
      (e) => e.name == severityText,
      orElse: () => throw FormatException('Invalid fire severity'),
    );
    return FireIncidentGIS(
      id: j['id'].toString(),
      position: LatLng(
        (j['lat'] as num).toDouble(),
        (j['lng'] as num).toDouble(),
      ),
      severity: severity,
      title: j['title'].toString(),
      detectionTime: DateTime.parse(j['detectionTime'].toString()),
      status: j['status'].toString(),
    );
  }
}

class RiskZoneGIS {
  final String id;
  final List<LatLng> polygon;
  final double riskScore;

  RiskZoneGIS({
    required this.id,
    required this.polygon,
    required this.riskScore,
  });

  factory RiskZoneGIS.fromJson(Map<String, dynamic> j) {
  return RiskZoneGIS(
    id: j['id'].toString(),
    polygon: (j['polygon'] as List).map((p) {
      return LatLng(
        (p[0] as num).toDouble(),
        (p[1] as num).toDouble(),
      );
    }).toList(),
    riskScore: (j['riskScore'] as num).toDouble(),
  );
}
}

class FireGuardCapsule {
  final String id;
  final LatLng position;
  final String status;
  final double batteryLevel;
  final String solarStatus;
  final String communicationStatus;
  final String sensorStatus;
  final DateTime lastCommunicationTime;

  FireGuardCapsule({
    required this.id,
    required this.position,
    required this.status,
    required this.batteryLevel,
    required this.solarStatus,
    required this.communicationStatus,
    required this.sensorStatus,
    required this.lastCommunicationTime,
  });

  factory FireGuardCapsule.fromJson(Map<String, dynamic> j) {
  return FireGuardCapsule(
    id: j['id'].toString(),
    position: LatLng(
      double.parse(j['latitude'].toString()),
double.parse(j['longitude'].toString()),
    ),
    status: j['status'].toString(),
    batteryLevel: j['battery_level'] == null
    ? 0.0
        : (j['battery_level'] as num).toDouble(),
    solarStatus: j['solar_status']?.toString()?? 'unknown',
    communicationStatus:
        j['communication_status']?.toString()?? 'unknown',
    sensorStatus: j['sensor_status']?.toString()?? 'unknown',
    lastCommunicationTime: j['last_communication'] == null
    ? DateTime.fromMillisecondsSinceEpoch(0)
        : DateTime.parse(j['last_communication'].toString()),
  );
}
}

class DashboardSummary {
  final int activeIncidents;
  final int totalCapsules;
  final int onlineCapsules;
  final int offlineCapsules;
  final int warningCapsules;
  final double readinessPercentage;
  final int availableResponseUnits;
  final int activeResponseUnits;
  final String systemHealth;
  final String fireRisk;

  DashboardSummary({
    required this.activeIncidents,
    required this.totalCapsules,
    required this.onlineCapsules,
    required this.offlineCapsules,
    required this.warningCapsules,
    required this.readinessPercentage,
    required this.availableResponseUnits,
    required this.activeResponseUnits,
    required this.systemHealth,
    required this.fireRisk,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> j) {
    return DashboardSummary(
      activeIncidents: (j['activeIncidents'] as num).toInt(),
      totalCapsules: (j['totalCapsules'] as num).toInt(),
      onlineCapsules: (j['onlineCapsules'] as num).toInt(),
      offlineCapsules: (j['offlineCapsules'] as num).toInt(),
      warningCapsules: (j['warningCapsules'] as num).toInt(),
      readinessPercentage: (j['readinessPercentage'] as num).toDouble(),
      availableResponseUnits: (j['availableResponseUnits'] as num).toInt(),
      activeResponseUnits: (j['activeResponseUnits'] as num).toInt(),
      systemHealth: j['systemHealth'].toString(),
      fireRisk: j['fireRisk'].toString(),
    );
  }
}

class SystemHealth {
  final String overallHealth;
  final String communicationHealth;
  final String sensorHealth;
  final String batteryHealth;
  final String solarHealth;
  final String capsuleStatus;
  final String communicationStatus;
  final String solarStatus;
  final String batteryStatus;
  final String sensorStatus;

  SystemHealth({
    required this.overallHealth,
    required this.communicationHealth,
    required this.sensorHealth,
    required this.batteryHealth,
    required this.solarHealth,
    required this.capsuleStatus,
    required this.communicationStatus,
    required this.solarStatus,
    required this.batteryStatus,
    required this.sensorStatus,
  });

  factory SystemHealth.fromJson(Map<String, dynamic> j) {
    return SystemHealth(
      overallHealth: j['overallHealth'].toString(),
      communicationHealth: j['communicationHealth'].toString(),
      sensorHealth: j['sensorHealth'].toString(),
      batteryHealth: j['batteryHealth'].toString(),
      solarHealth: j['solarHealth'].toString(),
      capsuleStatus: j['capsuleStatus'].toString(),
      communicationStatus: j['communicationStatus'].toString(),
      solarStatus: j['solarStatus'].toString(),
      batteryStatus: j['batteryStatus'].toString(),
      sensorStatus: j['sensorStatus'].toString(),
    );
  }
}

// ==================== AI ANALYSIS MODEL ADDED ====================
class AIAnalysis {
  final String classification;
  final double confidence;
  final String severity;
  final int riskScore;
  final String explanation;

  AIAnalysis({
    required this.classification,
    required this.confidence,
    required this.severity,
    required this.riskScore,
    required this.explanation,
  });

  factory AIAnalysis.fromJson(Map<String, dynamic> json) {
    return AIAnalysis(
      classification: json['classification']?.toString()?? '',
      confidence: (json['confidence'] as num?)?.toDouble()?? 0,
      severity: json['severity']?.toString()?? '',
      riskScore: (json['risk_score'] as num?)?.toInt()?? 0,
      explanation: json['explanation']?.toString()?? '',
    );
  }
}
// ================================================================

// ==================== COLORS & ENUMS ====================

class FGColors {
  static const bg = Color(0xFF07111F);
  static const surface = Color(0xFF0D1B2A);
  static const elevated = Color(0xFF13263A);
  static const border = Color(0xFF1B3045);
  static const primaryText = Color(0xFFF5F7FA);
  static const secondaryText = Color(0xFF8FA3B8);
  static const operational = Color(0xFF25C281);
  static const warning = Color(0xFFFFB547);
  static const critical = Color(0xFFFF4D3D);
  static const info = Color(0xFF4DA3FF);
  static const sidebar = Color(0xFF091522);
}

enum NetworkStatus { online, degraded, offline }
enum DataState { loading, live, empty, error, offline, updating }

// ==================== API SERVICE ====================

class FireGuardGisApiService {
  final String baseUrl;
  FireGuardGisApiService({required this.baseUrl});

  Future<DashboardSummary> fetchDashboardSummary(String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/dashboard/summary'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 401) throw Exception('Authentication expired');
    if (res.statusCode!= 200) throw Exception('Dashboard request failed');
    final data = jsonDecode(res.body);
    if (data is! Map<String, dynamic>) throw Exception('Invalid dashboard response');
    return DashboardSummary.fromJson(data);
  }

  Future<List<FireGuardCapsule>> fetchCapsules(String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/capsules'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 401) throw Exception('Authentication expired');
    if (res.statusCode!= 200) throw Exception('Capsule request failed');
    final data = jsonDecode(res.body);
    if (data is! List) throw Exception('Invalid capsule response');
    return data.map((e) => FireGuardCapsule.fromJson(e)).toList();
  }

  Future<SystemHealth> fetchSystemHealth(String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/system/health'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 401) throw Exception('Authentication expired');
    if (res.statusCode!= 200) throw Exception('System health request failed');
    final data = jsonDecode(res.body);
    if (data is! Map<String, dynamic>) throw Exception('Invalid system health response');
    return SystemHealth.fromJson(data);
  }

  Future<List<FireIncidentGIS>> fetchFires(String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/gis/fires'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 401) throw Exception('Authentication expired');
    if (res.statusCode!= 200) throw Exception('Fire request failed');
    final data = jsonDecode(res.body);

    final List<dynamic> items;

    if (data is List) {
      items = data;
    } else if (data is Map<String, dynamic> && data['value'] is List) {
      items = data['value'];
    } else {
      throw Exception('Invalid fire response');
    }

    return items
      .map((e) => FireIncidentGIS.fromJson(e as Map<String, dynamic>))
      .toList();
  }

  Future<List<RiskZoneGIS>> fetchRiskZones(String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/gis/risk-zones'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 401) throw Exception('Authentication expired');
    if (res.statusCode!= 200) throw Exception('Risk-zone request failed');
    final data = jsonDecode(res.body);

    final List<dynamic> items;

    if (data is List) {
      items = data;
    } else if (data is Map<String, dynamic> && data['value'] is List) {
      items = data['value'];
    } else {
      throw Exception('Invalid risk-zone response');
    }

    return items
      .map((e) => RiskZoneGIS.fromJson(e as Map<String, dynamic>))
      .toList();
  }

  // === AI ANALYSIS METHOD ADDED - DO NOT REMOVE ===
  Future<AIAnalysis> analyzeAlert({
    required String token,
    required double temperature,
    required double smokeLevel,
    required double humidity,
    required double windSpeed,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/ai/analyze-alert'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'temperature': temperature,
        'smoke_level': smokeLevel,
        'humidity': humidity,
        'wind_speed': windSpeed,
      }),
    );

    if (res.statusCode == 401) {
      throw Exception('Authentication expired');
    }

    if (res.statusCode!= 200) {
      throw Exception(
        'AI analysis failed: ${res.statusCode} ${res.body}',
      );
    }

    final data = jsonDecode(res.body);

    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid AI response');
    }

    return AIAnalysis.fromJson(data);
  }
  // ================================================
}

// ==================== DASHBOARD ====================

class FireGuardDashboard extends StatefulWidget {
  const FireGuardDashboard({super.key});
  @override
  State<FireGuardDashboard> createState() => _FireGuardDashboardState();
}

class _FireGuardDashboardState extends State<FireGuardDashboard>
    with TickerProviderStateMixin {
  NetworkStatus _networkStatus = NetworkStatus.online;
  DataState _mapState = DataState.loading;
  bool _isSyncing = false;
  DateTime _lastSync = DateTime.now();
  DateTime _lastUpdated = DateTime.now();
  String _selectedNav = 'Overview';
  final Set<String> _activeLayers = {'FireGuard Capsules', 'Active Fires'};
  late FireGuardGisApiService _gisService;

  List<FireIncidentGIS> _fires = [];
  List<RiskZoneGIS> _riskZones = [];
  List<FireGuardCapsule> _capsules = [];
  DashboardSummary? _dashboardSummary;
  SystemHealth? _systemHealth;

  final MapController _mapController = MapController();
  late AnimationController _criticalPulseController;

  final List<String> _navItems = [
    'Overview', 'Live Map', 'Incidents', 'Capsules', 'Risk Intelligence',
    'Alerts', 'System Health', 'Maintenance', 'Reports', 'Settings'
  ];
  final Map<String, IconData> _navIcons = {
    'Overview': Icons.grid_view_outlined,
    'Live Map': Icons.map_outlined,
    'Incidents': Icons.local_fire_department_outlined,
    'Capsules': Icons.sensors_outlined,
    'Risk Intelligence': Icons.shield_outlined,
    'Alerts': Icons.notifications_none_outlined,
    'System Health': Icons.show_chart_outlined,
    'Maintenance': Icons.build_outlined,
    'Reports': Icons.description_outlined,
    'Settings': Icons.settings_outlined,
  };

  // === NAVIGATION ADDED - DO NOT REMOVE ===
  void _navigateToCapsuleDetail(String capsuleId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FireGuardCapsuleDetailScreen(capsuleId: capsuleId),
      ),
    );
  }
  // ========================================

  @override
  void initState() {
    super.initState();
    _gisService = FireGuardGisApiService(baseUrl: 'http://127.0.0.1:8000');
    _criticalPulseController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
    _initConnectivity();
    _loadRealGisData();
  }

  void _initConnectivity() {
    Connectivity().onConnectivityChanged.listen((result) async {
      if (result.contains(ConnectivityResult.none)) {
        if (mounted) {
          setState(() {
            _networkStatus = NetworkStatus.offline;
            _mapState = DataState.offline;
          });
        }
      } else {
        await _loadRealGisData();
      }
    });
  }

  Future<String> _getAuthToken() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'access_token');
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found');
    }
    return token;
  }

  Future<void> _loadRealGisData() async {
    if (mounted) setState(() => _mapState = DataState.loading);
    try {
      final token = await _getAuthToken();
      debugPrint('STEP 1: Loading dashboard summary...');
      final summary = await _gisService.fetchDashboardSummary(token);
      debugPrint('STEP 1 OK');

      debugPrint('STEP 2: Loading fires...');
      final fires = await _gisService.fetchFires(token);
      debugPrint('STEP 2 OK');

      debugPrint('STEP 3: Loading risk zones...');
      final riskZones = await _gisService.fetchRiskZones(token);
      debugPrint('STEP 3 OK');

      debugPrint('STEP 4: Loading capsules...');
      final capsules = await _gisService.fetchCapsules(token);
      debugPrint('STEP 4 OK - CAPSULES: ${capsules.length}');

      debugPrint('STEP 5: Loading system health...');
      final systemHealth = await _gisService.fetchSystemHealth(token);
      debugPrint('STEP 5 OK');

      if (mounted) {
        setState(() {
          _dashboardSummary = summary;
          _fires = fires;
          _riskZones = riskZones;
          _capsules = capsules;
          _systemHealth = systemHealth;
          _mapState = DataState.live;
          _lastUpdated = DateTime.now();
          _networkStatus = NetworkStatus.online;
        });
      }
    } catch (e) {
      debugPrint('========================================');
debugPrint('FIREGUARD DASHBOARD DATA ERROR');
debugPrint(e.toString());
debugPrint('========================================');
      if (mounted) {
        setState(() {
          if (e.toString().contains('Authentication expired') ||
              e.toString().contains('Authentication token not found')) {
            _mapState = DataState.error;
          } else if (_fires.isEmpty && _dashboardSummary == null) {
            _mapState = DataState.error;
          } else {
            _mapState = DataState.live;
          }
        });
      }
    }
  }

  Future<void> _handleSync() async {
    if (_isSyncing) return;
    setState(() {
      _isSyncing = true;
      _mapState = DataState.updating;
    });
    await _loadRealGisData();
    if (mounted) {
      setState(() {
        _isSyncing = false;
        _lastSync = DateTime.now();
      });
    }
  }

  String get _syncText {
    final diff = DateTime.now().difference(_lastSync).inSeconds;
    if (diff < 60) return 'Last synchronized ${diff} sec ago';
    return 'Last synchronized ${DateFormat('HH:mm:ss').format(_lastSync)}';
  }

  @override
  void dispose() {
    _criticalPulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final isPhone = w < 600;
      final isTablet = w >= 600 && w < 1000;
      final isLaptop = w >= 1000;

      return Scaffold(
        backgroundColor: FGColors.bg,
        body: Row(children: [
          if (isLaptop) _buildSidebar(),
          if (isTablet) _buildRail(),
          Expanded(
              child: Column(children: [
            _buildHeader(isPhone, isTablet, isLaptop),
            Expanded(
                child: Center(
                    child: Container(
                        constraints: const BoxConstraints(maxWidth: 1680),
                        child: SingleChildScrollView(
                            padding: EdgeInsets.symmetric(
                              horizontal: isPhone? 12 : 20,
                              vertical: isPhone? 12 : 20,
                            ),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildTitleBar(isPhone),
                                  const SizedBox(height: 20),
                                  _buildStatusCards(isPhone, isTablet, isLaptop),
                                  const SizedBox(height: 20),
                                  _buildMainOperational(isPhone, isTablet, isLaptop),
                                  const SizedBox(height: 20),
                                  _buildNetworkHealth(isPhone, isTablet, isLaptop),
                                ]))))),
          ])),
        ]),
        bottomNavigationBar: isPhone? _buildBottomNav() : null,
      );
    });
  }

  Widget _buildSidebar() {
    return Container(
        width: 240,
        height: double.infinity,
        color: FGColors.sidebar,
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                    color: FGColors.critical, borderRadius: BorderRadius.circular(6)),
                child: const Icon(Icons.shield, color: Colors.white, size: 16)),
            const SizedBox(width: 8),
            Text('FireGuard',
                style: GoogleFonts.inter(
                    color: FGColors.primaryText, fontWeight: FontWeight.w700, fontSize: 18))
          ]),
          const SizedBox(height: 24),
     ..._navItems.map((e) {
            final sel = e == _selectedNav;
            return Container(
                height: 44,
                margin: const EdgeInsets.only(bottom: 2),
                decoration: BoxDecoration(
                    color: sel? FGColors.elevated : Colors.transparent,
                    borderRadius: BorderRadius.circular(8)),
                child: InkWell(
                    onTap: () {
                      if (e == 'Capsules') {
                        // === NAVIGATION ADDED ===
                        if (_capsules.isNotEmpty) {
                          _navigateToCapsuleDetail(_capsules.first.id);
                        } else {
                          _navigateToCapsuleDetail('CAP-001');
                        }
                        return;
                      }
                      // ==========================
                      if (e == 'Alerts') {
                        Navigator.pushNamed(context, '/alerts');
                      } else if (e == 'Live Map') {
                        Navigator.pushNamed(context, '/map');
                      } else {
                        setState(() => _selectedNav = e);
                      }
                    },
                    child: Row(children: [
                      const SizedBox(width: 12),
                      Icon(_navIcons[e],
                          size: 20,
                          color: sel? FGColors.primaryText : FGColors.secondaryText),
                      const SizedBox(width: 12),
                      Text(e,
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: sel? FGColors.primaryText : FGColors.secondaryText))
                    ])));
          }),
        ]));
  }

  Widget _buildRail() => Container(
      width: 64,
      color: FGColors.sidebar,
      child: Column(
          children: _navItems
         .map((e) => InkWell(
                  onTap: () {
                    if (e == 'Capsules') {
                      if (_capsules.isNotEmpty) {
                        _navigateToCapsuleDetail(_capsules.first.id);
                      } else {
                        _navigateToCapsuleDetail('CAP-001');
                      }
                      return;
                    }
                    if (e == 'Alerts') {
                      Navigator.pushNamed(context, '/alerts');
                    } else if (e == 'Live Map') {
                      Navigator.pushNamed(context, '/map');
                    } else {
                      setState(() => _selectedNav = e);
                    }
                  },
                  child: Container(
                      height: 56,
                      width: 64,
                      color: e == _selectedNav? FGColors.elevated : Colors.transparent,
                      child: Icon(_navIcons[e],
                          size: 22,
                          color: e == _selectedNav
                         ? FGColors.primaryText
                              : FGColors.secondaryText))))
         .toList()));

  Widget _buildHeader(bool isPhone, bool isTablet, bool isLaptop) {
    return Container(
      height: isPhone? 60 : 72,
      padding: EdgeInsets.symmetric(horizontal: isPhone? 12 : 20),
      decoration: const BoxDecoration(
          color: FGColors.surface,
          border: Border(bottom: BorderSide(color: FGColors.border))),
      child: Row(
        children: [
          if (!isPhone)...[
            Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                    color: FGColors.critical, borderRadius: BorderRadius.circular(6)),
                child: const Icon(Icons.shield, color: Colors.white, size: 16)),
            const SizedBox(width: 10),
            if (isLaptop)
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('FireGuard',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: FGColors.primaryText)),
                      Text('National Wildfire Command Center',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              fontSize: 11, color: FGColors.secondaryText))
                    ]),
              ),
          ],
          if (isPhone) const Spacer(),
          if (isLaptop)
            Flexible(
              child: Text(_syncText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 11, color: FGColors.secondaryText)),
            ),
          if (isLaptop) const SizedBox(width: 12),
          _iconBtn(Icons.sync, _isSyncing, _handleSync),
          const SizedBox(width: 8),
          _buildNetworkStatusChip(),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => Navigator.pushNamed(context, '/alerts'),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: FGColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.notifications_none,
                size: 20,
                color: FGColors.primaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, bool loading, VoidCallback tap) => InkWell(
      onTap: tap,
      child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              border: Border.all(color: FGColors.border),
              borderRadius: BorderRadius.circular(8)),
          child: loading
         ? const Padding(
                  padding: EdgeInsets.all(10),
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(icon, size: 20, color: FGColors.primaryText)));

  Widget _buildNetworkStatusChip() {
    Color c;
    String t;
    switch (_networkStatus) {
      case NetworkStatus.online:
        c = FGColors.operational;
        t = 'SYSTEM ONLINE';
        break;
      case NetworkStatus.degraded:
        c = FGColors.warning;
        t = 'DEGRADED';
        break;
      case NetworkStatus.offline:
        c = FGColors.critical;
        t = 'OFFLINE';
        break;
    }
    return Container(
      constraints: const BoxConstraints(minWidth: 40, maxWidth: 130),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              t,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: c),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleBar(bool isPhone) {
    final title = Text(
      'National Command Center',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.inter(
        fontSize: isPhone? 22 : 28,
        fontWeight: FontWeight.w700,
        color: FGColors.primaryText,
      ),
    );
    final subtitle = Text(
      'Real-time wildfire monitoring, prediction and first-response coordination',
      maxLines: isPhone? 3 : 2,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.inter(fontSize: 13, color: FGColors.secondaryText),
    );
    final updated = Text(
      'Last updated: ${DateFormat('HH:mm:ss').format(_lastUpdated)}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.inter(fontSize: 12, color: FGColors.secondaryText),
    );
    if (isPhone) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          const SizedBox(height: 4),
          subtitle,
          const SizedBox(height: 6),
          updated,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 4), subtitle],
          ),
        ),
        const SizedBox(width: 16),
        Flexible(child: Align(alignment: Alignment.topRight, child: updated)),
      ],
    );
  }

  Widget _buildStatusCards(bool isPhone, bool isTablet, bool isLaptop) {
    final columns = isPhone? 2 : isTablet? 3 : 5;
    final aspect = isPhone? 1.55 : isTablet? 1.8 : 2.0;

    if (_dashboardSummary == null) {
      return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              childAspectRatio: aspect,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12),
          itemCount: 5,
          itemBuilder: (_, i) => _buildStatusCard(
              label: [
                'ACTIVE INCIDENTS',
                'CAPSULE NETWORK',
                'RESPONSE READINESS',
                'SYSTEM HEALTH',
                'FIRE RISK'
              ][i],
              value: '...',
              secondary: 'Loading real data...'));
    }

    final s = _dashboardSummary!;
    final items = [
      {'label': 'ACTIVE INCIDENTS', 'value': '${s.activeIncidents}', 'secondary': '${s.activeResponseUnits} responding'},
      {'label': 'CAPSULE NETWORK', 'value': '${s.totalCapsules}', 'secondary': '${s.onlineCapsules} online'},
      {'label': 'RESPONSE READINESS', 'value': '${s.readinessPercentage.toStringAsFixed(0)}%', 'secondary': '${s.availableResponseUnits} units ready'},
      {'label': 'SYSTEM HEALTH', 'value': s.systemHealth, 'secondary': '${s.onlineCapsules}/${s.totalCapsules} operational'},
      {'label': 'FIRE RISK', 'value': s.fireRisk, 'secondary': '${s.warningCapsules} warnings'},
    ];

    return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            childAspectRatio: aspect,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12),
        itemCount: items.length,
        itemBuilder: (_, i) => InkWell(
          // === NAVIGATION ADDED: tap status card to open detail ===
          onTap: () {
            if ((items[i]['label'] as String).contains('CAPSULE')) {
              if (_capsules.isNotEmpty) {
                _navigateToCapsuleDetail(_capsules.first.id);
              } else {
                _navigateToCapsuleDetail('CAP-001');
              }
            }
          },
          child: _buildStatusCard(
            label: items[i]['label'] as String,
            value: items[i]['value'] as String,
            secondary: items[i]['secondary'] as String),
        ));
  }

  Widget _buildStatusCard({required String label, required String value, required String secondary}) {
    return Container(
      constraints: const BoxConstraints(minHeight: 90),
      decoration: BoxDecoration(
          color: FGColors.surface,
          border: Border.all(color: FGColors.border),
          borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.all(14),
child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Row(
      children: [
        const Icon(
          Icons.local_fire_department_outlined,
          size: 16,
          color: FGColors.secondaryText,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: FGColors.secondaryText,
            ),
          ),
        ),
      ],
    ),
    const SizedBox(height: 2),
    Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: FGColors.primaryText,
      ),
    ),
    const SizedBox(height: 2),
    Text(
      secondary,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.inter(
        fontSize: 10,
        color: FGColors.secondaryText,
      ),
    ),
  ],
),

  Widget _buildMainOperational(bool isPhone, bool isTablet, bool isLaptop) {
    final mapHeight = isPhone? 360.0 : 420.0;
    if (isLaptop) {
      return SizedBox(
          height: 460,
          child: Row(children: [
            Expanded(flex: 65, child: _buildMapPanel(height: 460, isPhone: isPhone)),
            const SizedBox(width: 16),
            Expanded(flex: 35, child: _buildIncidentsPanel(height: 460))
          ]));
    } else {
      return Column(children: [
        _buildMapPanel(height: mapHeight, isPhone: isPhone),
        const SizedBox(height: 16),
        _buildIncidentsPanel(height: mapHeight)
      ]);
    }
  }

  Widget _buildMapPanel({required double height, required bool isPhone}) {
    return Container(
        height: height,
        decoration: BoxDecoration(
            color: FGColors.surface,
            border: Border.all(color: FGColors.border),
            borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          Container(
            height: 56,
            padding: EdgeInsets.symmetric(horizontal: isPhone? 12 : 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: FGColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Live Protection Map',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: FGColors.primaryText,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_mapState == DataState.live)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: FGColors.operational.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: FGColors.operational,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'LIVE',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: FGColors.operational,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      if (!isPhone)
                        Text(
                          'FlutterMap + OSM • Real GIS',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: FGColors.secondaryText,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildLayerToggle(),
              ],
            ),
          ),
          Expanded(child: _buildFlutterMap()),
        ]));
  }

  Widget _buildLayerToggle() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.layers_outlined, size: 18, color: FGColors.secondaryText),
      onSelected: (v) {
        setState(() {
          if (_activeLayers.contains(v)) {
            _activeLayers.remove(v);
          } else {
            _activeLayers.add(v);
          }
        });
      },
      itemBuilder: (_) {
        const layers = [
          'FireGuard Capsules', 'Active Fires', 'Fire-Risk Zones',
          'Predicted Spread', 'Wind', 'Protected Areas',
          'Roads', 'Water Sources', 'Power Lines',
        ];
        return layers.map((e) {
          return PopupMenuItem<String>(
            value: e,
            child: SizedBox(
              width: 220,
              child: Row(
                children: [
                  Checkbox(value: _activeLayers.contains(e), onChanged: (_) {}),
                  Expanded(
                    child: Text(
                      e,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList();
      },
    );
  }

  Widget _buildFlutterMap() {
    if (_mapState == DataState.loading || _mapState == DataState.updating) {
      return const Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        CircularProgressIndicator(),
        SizedBox(height: 8),
        Text('Loading real GIS data...', style: TextStyle(color: FGColors.secondaryText))
      ]));
    }

    final markers = <Marker>[];
    final capsuleMarkers = <Marker>[];

    for (var fire in _fires) {
      if (!_activeLayers.contains('Active Fires')) continue;
      final isCritical = fire.severity == AlertSeverity.critical;
      markers.add(Marker(
        point: fire.position,
        width: isCritical? 48 : 36,
        height: isCritical? 48 : 36,
        child: GestureDetector(
          onTap: () => _showFireDetails(fire),
          child: isCritical
         ? AnimatedBuilder(
                  animation: _criticalPulseController,
                  builder: (_, __) {
                    return Stack(alignment: Alignment.center, children: [
                      Container(
                          width: 48 + 12 * _criticalPulseController.value,
                          height: 48 + 12 * _criticalPulseController.value,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: FGColors.critical
                             .withOpacity(0.3 - 0.2 * _criticalPulseController.value))),
                      Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                              color: FGColors.critical,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2)),
                          child: const Icon(Icons.local_fire_department,
                              size: 16, color: Colors.white)),
                    ]);
                  })
              : Container(
                  decoration: BoxDecoration(
                      color: fire.severity == AlertSeverity.warning
                     ? FGColors.warning
                          : FGColors.info,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2)),
                  child: const Icon(Icons.local_fire_department,
                      size: 14, color: Colors.white)),
        ),
      ));
    }

    if (_activeLayers.contains('FireGuard Capsules')) {
      for (var capsule in _capsules) {
        final isOnline = capsule.status.toLowerCase() == 'online';
        final isWarning = capsule.status.toLowerCase() == 'warning';
        Color c = isOnline? FGColors.operational : isWarning? FGColors.warning : FGColors.secondaryText;
        capsuleMarkers.add(Marker(
            point: capsule.position,
            width: 30,
            height: 30,
            child: GestureDetector(
              onTap: () => _showCapsuleDetails(capsule),
              child: Container(
                decoration: BoxDecoration(
                    color: c, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                child: Icon(isOnline? Icons.sensors : Icons.sensors_off, size: 14, color: Colors.white),
              ),
            )));
      }
    }

    return FlutterMap(
      mapController: _mapController,
      options: const MapOptions(
          initialCenter: LatLng(-24.6282, 25.9231), initialZoom: 5.5, maxZoom: 18, minZoom: 3),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.fireguard.app',
        ),
        if (_activeLayers.contains('Fire-Risk Zones') && _riskZones.isNotEmpty)
          PolygonLayer(
            polygons: _riskZones.map((z) {
              return Polygon(
                points: z.polygon,
                color: FGColors.critical.withOpacity(0.2 + (z.riskScore * 0.3)),
                borderColor: FGColors.critical,
                borderStrokeWidth: 1.5,
              );
            }).toList(),
          ),
        MarkerLayer(markers: [...markers,...capsuleMarkers]),
        RichAttributionWidget(
          attributions: [
            TextSourceAttribution('© OpenStreetMap contributors', onTap: () {}),
            TextSourceAttribution('FireGuard GIS - Real Data', onTap: () {}),
          ],
        ),
      ],
    );
  }

  void _showFireDetails(FireIncidentGIS fire) {
    showModalBottomSheet(
        context: context,
        backgroundColor: FGColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        builder: (_) => Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fire.title,
                        style: GoogleFonts.inter(
                            fontSize: 16, fontWeight: FontWeight.w700, color: FGColors.primaryText)),
                    const SizedBox(height: 12),
                    _detailRow('ID', fire.id),
                    _detailRow('Severity', fire.severity.name),
                    _detailRow('Status', fire.status),
                    _detailRow('Detection', DateFormat('yyyy-MM-dd HH:mm:ss').format(fire.detectionTime)),
                    _detailRow('Latitude', fire.position.latitude.toStringAsFixed(6)),
                    _detailRow('Longitude', fire.position.longitude.toStringAsFixed(6)),
                  ]),
            ));
  }

  void _showCapsuleDetails(FireGuardCapsule c) {
    showModalBottomSheet(
        context: context,
        backgroundColor: FGColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        builder: (_) => Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Capsule ${c.id}',
                        style: GoogleFonts.inter(
                            fontSize: 16, fontWeight: FontWeight.w700, color: FGColors.primaryText)),
                    const SizedBox(height: 12),
                    _detailRow('Status', c.status),
                    _detailRow('Battery', '${c.batteryLevel.toStringAsFixed(1)}%'),
                    _detailRow('Solar', c.solarStatus),
                    _detailRow('Communication', c.communicationStatus),
                    _detailRow('Sensor', c.sensorStatus),
                    _detailRow('Last Comm', DateFormat('yyyy-MM-dd HH:mm:ss').format(c.lastCommunicationTime)),
                    _detailRow('Position',
                        '${c.position.latitude.toStringAsFixed(5)}, ${c.position.longitude.toStringAsFixed(5)}'),
                    const SizedBox(height: 16),
                    // === NAVIGATION ADDED ===
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _navigateToCapsuleDetail(c.id);
                        },
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: Text('OPEN CAPSULE DETAIL', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FGColors.info,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    // ==========================
                  ]),
            ));
  }

  Widget _detailRow(String k, String v) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        SizedBox(
            width: 110,
            child: Text(k, style: GoogleFonts.inter(fontSize: 12, color: FGColors.secondaryText))),
        Expanded(child: Text(v, style: GoogleFonts.inter(fontSize: 13, color: FGColors.primaryText)))
      ]));

  Widget _buildIncidentsPanel({required double height}) => Container(
      height: height,
      decoration: BoxDecoration(
          color: FGColors.surface,
          border: Border.all(color: FGColors.border),
          borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration:
                const BoxDecoration(border: Border(bottom: BorderSide(color: FGColors.border))),
            child: Row(children: [
              Text('ACTIVE INCIDENTS',
                  style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w600, color: FGColors.primaryText)),
              const Spacer(),
              Text('${_fires.length}', style: GoogleFonts.inter(color: FGColors.secondaryText))
            ])),
        Expanded(
            child: _fires.isEmpty
           ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.check_circle_outline, color: FGColors.secondaryText, size: 32),
                    const SizedBox(height: 8),
                    Text('No active incidents',
                        style: GoogleFonts.inter(
                            color: FGColors.primaryText, fontSize: 13, fontWeight: FontWeight.w500)),
                    Text('Real GIS: awaiting backend fires',
                        style: GoogleFonts.inter(color: FGColors.secondaryText, fontSize: 11))
                  ]))
                : ListView.builder(
                    itemCount: _fires.length,
                    itemBuilder: (_, i) {
                      final f = _fires[i];
                      return ListTile(
                          leading: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                  color: f.severity == AlertSeverity.critical
                                 ? FGColors.critical
                                      : FGColors.warning,
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.local_fire_department,
                                  size: 16, color: Colors.white)),
                          title: Text(f.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(fontSize: 13, color: FGColors.primaryText)),
                          subtitle: Text('${f.status} • ${DateFormat('HH:mm').format(f.detectionTime)}',
                              style: GoogleFonts.inter(fontSize: 11, color: FGColors.secondaryText)),
                          onTap: () {
                            _mapController.move(f.position, 12);
                            _showFireDetails(f);
                          });
                    })),
      ]));

  Widget _buildNetworkHealth(bool isPhone, bool isTablet, bool isLaptop) {
    final columns = isPhone? 2 : isTablet? 3 : 5;
    if (_systemHealth == null) {
      return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: FGColors.surface,
              border: Border.all(color: FGColors.border),
              borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('NETWORK HEALTH',
                style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w600, color: FGColors.secondaryText)),
            const SizedBox(height: 16),
            GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns, childAspectRatio: 2.5, crossAxisSpacing: 12, mainAxisSpacing: 12),
                itemCount: 5,
                itemBuilder: (_, i) => _healthItem('Loading...', '—'))
          ]));
    }
    final h = _systemHealth!;
    final items = [
      {'l': 'Capsules', 'v': h.capsuleStatus},
      {'l': 'Communication', 'v': h.communicationStatus},
      {'l': 'Solar', 'v': h.solarStatus},
      {'l': 'Battery', 'v': h.batteryStatus},
      {'l': 'Sensors', 'v': h.sensorStatus},
    ];
    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: FGColors.surface,
            border: Border.all(color: FGColors.border),
            borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('NETWORK HEALTH',
              style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w600, color: FGColors.secondaryText)),
          const SizedBox(height: 16),
          GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns, childAspectRatio: 2.5, crossAxisSpacing: 12, mainAxisSpacing: 12),
              itemCount: items.length,
              itemBuilder: (_, i) => _healthItem(items[i]['l'] as String, items[i]['v'] as String))
        ]));
  }

  Widget _healthItem(String l, String v) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FGColors.elevated,
        border: Border.all(color: FGColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(fontSize: 11, color: FGColors.secondaryText),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              v,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: FGColors.primaryText,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 3,
            width: double.infinity,
            decoration: BoxDecoration(
              color: FGColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() => BottomNavigationBar(
      backgroundColor: FGColors.sidebar,
      selectedItemColor: FGColors.primaryText,
      unselectedItemColor: FGColors.secondaryText,
      type: BottomNavigationBarType.fixed,
      onTap: (i) {
        if (i == 3) {
          if (_capsules.isNotEmpty) {
            _navigateToCapsuleDetail(_capsules.first.id);
          } else {
            _navigateToCapsuleDetail('CAP-001');
          }
          return;
        }
        if (i == 1) Navigator.pushNamed(context, '/map');
        if (i == 2) Navigator.pushNamed(context, '/alerts');
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.grid_view_outlined), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Map'),
        BottomNavigationBarItem(icon: Icon(Icons.notifications_none_outlined), label: 'Alerts'),
        BottomNavigationBarItem(icon: Icon(Icons.sensors_outlined), label: 'Capsules'),
        BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'More')
      ]);
}