import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:intl/intl.dart';

// ===============================================================
// FIREGUARD CONFIGURATION - NO MOCK DATA, REAL BACKEND ONLY
// ===============================================================
class FireGuardConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'FIREGUARD_API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );
  static const Duration apiTimeout = Duration(seconds: 15);
}

// ===============================================================
// COLORS - Professional Dark Theme
// ===============================================================
class FireColors {
  static const bg = Color(0xFF07111F);
  static const cardBg = Color(0xFF0D1B2A);
  static const drawerBg = Color(0xFF13263A);
  static const border = Color(0xFF1B3045);
  static const primaryText = Color(0xFFF5F7FA);
  static const secondaryText = Color(0xFF8FA3B8);
  static const critical = Color(0xFFFF4D3D);
  static const warning = Color(0xFFFFB547);
  static const operational = Color(0xFF25C281);
  static const info = Color(0xFF4DA3FF);
}

// ===============================================================
// MODELS
// ===============================================================
enum AlertSeverity { critical, warning, info }
enum AlertStatus { active, acknowledged, resolved }
enum ConnectionStatus { connected, reconnecting, offline }
enum VoiceState { idle, listening, processing, speaking, error }
enum AlertViewMode { alerts, notifications }

extension AlertSeverityX on AlertSeverity {
  static AlertSeverity fromString(String? v) {
    switch (v?.toLowerCase()) {
      case 'critical':
        return AlertSeverity.critical;
      case 'warning':
        return AlertSeverity.warning;
      default:
        return AlertSeverity.info;
    }
  }
}

extension AlertStatusX on AlertStatus {
  static AlertStatus fromString(String? v) {
    switch (v?.toLowerCase()) {
      case 'acknowledged':
        return AlertStatus.acknowledged;
      case 'resolved':
        return AlertStatus.resolved;
      default:
        return AlertStatus.active;
    }
  }
}

class AlertTimelineEvent {
  final DateTime time;
  final String description;
  final String source;
  final String status;
  AlertTimelineEvent({
    required this.time,
    required this.description,
    required this.source,
    required this.status,
  });
  factory AlertTimelineEvent.fromJson(Map<String, dynamic> j) =>
      AlertTimelineEvent(
        time: DateTime.tryParse(j['time']?.toString()?? '')?? DateTime.now(),
        description: j['description']?.toString()?? '',
        source: j['source']?.toString()?? 'System',
        status: j['status']?.toString()?? 'INFO',
      );
}

class AlertEvidence {
  final double? temperature;
  final double? smokeLevel;
  final double? humidity;
  final double? windSpeed;
  final int? battery;
  final String? solarStatus;
  final String? networkStatus;
  final double? gpsLat;
  final double? gpsLng;
  final String? deviceId;
  final String? deviceStatus;
  final double? aiConfidence;
  final String? aiVerification;
  final String? fireClassification;
  const AlertEvidence({
    this.temperature,
    this.smokeLevel,
    this.humidity,
    this.windSpeed,
    this.battery,
    this.solarStatus,
    this.networkStatus,
    this.gpsLat,
    this.gpsLng,
    this.deviceId,
    this.deviceStatus,
    this.aiConfidence,
    this.aiVerification,
    this.fireClassification,
  });
  factory AlertEvidence.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const AlertEvidence();
    return AlertEvidence(
      temperature: (j['temperature'] as num?)?.toDouble(),
      smokeLevel: (j['smokeLevel'] as num?)?.toDouble(),
      humidity: (j['humidity'] as num?)?.toDouble(),
      windSpeed: (j['windSpeed'] as num?)?.toDouble(),
      battery: j['battery'] is int? j['battery'] as int : (j['battery'] as num?)?.toInt(),
      solarStatus: j['solarStatus']?.toString(),
      networkStatus: j['networkStatus']?.toString(),
      gpsLat: (j['gpsLat'] as num?)?.toDouble(),
      gpsLng: (j['gpsLng'] as num?)?.toDouble(),
      deviceId: j['deviceId']?.toString(),
      deviceStatus: j['deviceStatus']?.toString(),
      aiConfidence: (j['aiConfidence'] as num?)?.toDouble(),
      aiVerification: j['aiVerification']?.toString(),
      fireClassification: j['fireClassification']?.toString(),
    );
  }
}

class FireGuardAiResult {
  final String classification;
  final double confidence;
  final String severity;
  final int riskScore;
  final bool flameDetected;
  final Map<String, String> sensorStatus;
  final int criticalConditions;
  final int elevatedConditions;
  final String explanation;

  const FireGuardAiResult({
    required this.classification,
    required this.confidence,
    required this.severity,
    required this.riskScore,
    required this.flameDetected,
    required this.sensorStatus,
    required this.criticalConditions,
    required this.elevatedConditions,
    required this.explanation,
  });

  factory FireGuardAiResult.fromJson(Map<String, dynamic> json) {
    final rawSensorStatus = json['sensor_status'];
    return FireGuardAiResult(
      classification: json['classification']?.toString()?? 'UNKNOWN',
      confidence: (json['confidence'] as num?)?.toDouble()?? 0.0,
      severity: json['severity']?.toString()?? 'INFO',
      riskScore: (json['risk_score'] as num?)?.toInt()?? 0,
      flameDetected: json['flame_detected'] == true,
      sensorStatus: rawSensorStatus is Map
         ? rawSensorStatus.map((key, value) => MapEntry(key.toString(), value.toString()))
          : {},
      criticalConditions: (json['critical_conditions'] as num?)?.toInt()?? 0,
      elevatedConditions: (json['elevated_conditions'] as num?)?.toInt()?? 0,
      explanation: json['explanation']?.toString()?? '',
    );
  }
}

class AlertModel {
  final String id;
  final String incidentId;
  final String fireId;
  final String capsuleId;
  final String title;
  final AlertSeverity severity;
  AlertStatus status;
  final String alertType;
  final String location;
  final double? latitude;
  final double? longitude;
  final DateTime detectionTime;
  DateTime lastUpdated;
  final DateTime? lastCommunication;
  final String? incidentStatus;
  final String? responseStatus;
  final String? suppressionStatus;
  final DateTime? responseActivationTime;
  final String sourceDevice;
  final AlertEvidence evidence;
  final Map<String, dynamic> rawSensor;
  bool isUnread;
  DateTime? acknowledgedAt;
  String? acknowledgedBy;
  DateTime? resolvedAt;
  String? resolvedBy;
  List<AlertTimelineEvent> timeline;

  AlertModel({
    required this.id,
    required this.incidentId,
    required this.title,
    required this.severity,
    required this.status,
    required this.detectionTime,
    required this.lastUpdated,
    required this.location,
    required this.sourceDevice,
    required this.alertType,
    required this.capsuleId,
    required this.fireId,
    required this.evidence,
    required this.rawSensor,
    this.latitude,
    this.longitude,
    this.lastCommunication,
    this.incidentStatus,
    this.responseStatus,
    this.suppressionStatus,
    this.responseActivationTime,
    this.isUnread = true,
    this.acknowledgedAt,
    this.acknowledgedBy,
    this.resolvedAt,
    this.resolvedBy,
    List<AlertTimelineEvent>? timeline,
  }) : timeline = timeline?? [];

  factory AlertModel.fromJson(Map<String, dynamic> j) {
    return AlertModel(
      id: j['id']?.toString()?? j['alertId']?.toString()?? '',
      incidentId: j['incidentId']?.toString()?? '',
      fireId: j['fireId']?.toString()?? '',
      capsuleId: j['capsuleId']?.toString()?? '',
      title: j['title']?.toString()?? 'Untitled Alert',
      severity: AlertSeverityX.fromString(j['severity']?.toString()),
      status: AlertStatusX.fromString(j['status']?.toString()),
      alertType: j['alertType']?.toString()?? 'Unknown',
      location: j['location']?.toString()?? 'Unknown location',
      latitude: (j['latitude'] as num?)?.toDouble()?? (j['evidence']?['gpsLat'] as num?)?.toDouble(),
      longitude: (j['longitude'] as num?)?.toDouble()?? (j['evidence']?['gpsLng'] as num?)?.toDouble(),
      detectionTime: DateTime.tryParse(j['detectionTime']?.toString()?? '')?? DateTime.now(),
      lastUpdated: DateTime.tryParse(j['lastUpdated']?.toString()?? '')?? DateTime.now(),
      lastCommunication: j['lastCommunication']!= null? DateTime.tryParse(j['lastCommunication'].toString()) : null,
      incidentStatus: j['incidentStatus']?.toString(),
      responseStatus: j['responseStatus']?.toString(),
      suppressionStatus: j['suppressionStatus']?.toString(),
      responseActivationTime: j['responseActivationTime']!= null? DateTime.tryParse(j['responseActivationTime'].toString()) : null,
      sourceDevice: j['sourceDevice']?.toString()?? '',
      evidence: AlertEvidence.fromJson(j['evidence'] as Map<String, dynamic>?),
      rawSensor: (j['rawSensor'] as Map<String, dynamic>?)?? <String, dynamic>{},
      isUnread: (j['isUnread'] as bool?)?? true,
      acknowledgedAt: j['acknowledgedAt']!= null? DateTime.tryParse(j['acknowledgedAt'].toString()) : null,
      acknowledgedBy: j['acknowledgedBy']?.toString(),
      resolvedAt: j['resolvedAt']!= null? DateTime.tryParse(j['resolvedAt'].toString()) : null,
      resolvedBy: j['resolvedBy']?.toString(),
      timeline: ((j['timeline'] as List?)?? []).map((e) => AlertTimelineEvent.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class AuthService {
  Future<String?> getAccessToken() async {
    return 'dev-token';
  }
  Future<Map<String, dynamic>?> getCurrentOperator() async {
    return null;
  }
}

class AlertApiService {
  final String baseUrl;
  final http.Client _client;

  AlertApiService({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client?? http.Client();

  Map<String, String> _headers(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  Future<List<AlertModel>> fetchAlerts(String token) async {
    final res = await _client
       .get(
          Uri.parse('$baseUrl/api/alerts'),
          headers: _headers(token),
        )
       .timeout(FireGuardConfig.apiTimeout);

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body) as List;
      return data.map((e) => AlertModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('GET /api/alerts failed: ${res.statusCode}');
  }

  Future<Map<String, dynamic>> fetchLatestTelemetry(
    String capsuleId,
    String token,
  ) async {
    final response = await _client
       .get(
          Uri.parse('$baseUrl/api/capsules/$capsuleId/telemetry'),
          headers: _headers(token),
        )
       .timeout(FireGuardConfig.apiTimeout);

    if (response.statusCode!= 200) {
      throw Exception(
        'GET latest telemetry failed: '
        '${response.statusCode} ${response.body}',
      );
    }

    final data = jsonDecode(response.body);

    if (data is List) {
      if (data.isEmpty) {
        throw Exception('No telemetry available for capsule $capsuleId.');
      }
      return Map<String, dynamic>.from(data.first);
    }

    if (data is Map<String, dynamic>) {
      return data;
    }

    throw Exception('Unexpected telemetry response format.');
  }

  Future<void> acknowledge(String alertId, String token) async {
    final res = await _client.post(Uri.parse('$baseUrl/api/alerts/$alertId/acknowledge'), headers: _headers(token)).timeout(FireGuardConfig.apiTimeout);
    if (res.statusCode!= 200) {
      throw Exception('Acknowledge failed: ${res.statusCode}');
    }
  }

  Future<void> resolve(String alertId, String token) async {
    final res = await _client.post(Uri.parse('$baseUrl/api/alerts/$alertId/resolve'), headers: _headers(token)).timeout(FireGuardConfig.apiTimeout);
    if (res.statusCode!= 200) {
      throw Exception('Resolve failed: ${res.statusCode}');
    }
  }
}

class FireGuardAiService {
  final String baseUrl;
  final http.Client _client;
  FireGuardAiService({required this.baseUrl, http.Client? client}) : _client = client?? http.Client();

  Future<FireGuardAiResult> analyzeAlert({
    required double temperature,
    required double smokeLevel,
    required double humidity,
    required double windSpeed,
    double mq2 = 0.0,
    double mq7 = 0.0,
    double infraredTemperature = 0.0,
    bool flameDetected = false,
  }) async {
    final response = await _client
       .post(
          Uri.parse('$baseUrl/api/ai/analyze-alert'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'temperature': temperature,
            'smoke_level': smokeLevel,
            'humidity': humidity,
            'wind_speed': windSpeed,
            'mq2': mq2,
            'mq7': mq7,
            'infrared_temperature': infraredTemperature,
            'flame_detected': flameDetected,
          }),
        )
       .timeout(FireGuardConfig.apiTimeout);

    if (response.statusCode!= 200) {
      throw Exception('FireGuard AI failed: ${response.statusCode} ${response.body}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return FireGuardAiResult.fromJson(data);
  }
}

class AlertRepository {
  final AlertApiService api;
  final AuthService auth;

  AlertRepository({
    required this.api,
    required this.auth,
  });

  Future<List<AlertModel>> getAlerts() async {
    final token = await auth.getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }
    // No mock fallback - let error propagate to UI
    return await api.fetchAlerts(token);
  }

  Future<Map<String, dynamic>> getLatestTelemetry(String capsuleId) async {
    final token = await auth.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('Not authenticated');
    }
    return await api.fetchLatestTelemetry(capsuleId, token);
  }

  Future<void> acknowledgeAlert(String id) async {
    final token = await auth.getAccessToken();
    if (token == null) throw Exception('Not authenticated');
    await api.acknowledge(id, token);
  }

  Future<void> resolveAlert(String id) async {
    final token = await auth.getAccessToken();
    if (token == null) throw Exception('Not authenticated');
    await api.resolve(id, token);
  }
}

class AlertController extends ChangeNotifier {
  final AlertRepository repository;
  final AlertApiService _api;
  AlertController({required this.repository, AlertApiService? api}) : _api = api?? repository.api;

  List<AlertModel> allAlerts = [];
  List<AlertModel> filteredAlerts = [];
  AlertModel? selectedAlert;
  bool isLoading = true;
  bool isError = false;
  String? errorMessage;
  ConnectionStatus connectionStatus = ConnectionStatus.connected;
  DateTime? lastSync;
  String? highlightedId;

  String searchQuery = '';
  String statusFilter = 'All';
  String severityFilter = 'All';
  String typeFilter = 'All';
  String locationFilter = 'All';
  String timeFilter = 'All';
  String sortBy = 'Newest';
  AlertViewMode viewMode = AlertViewMode.alerts;

  Future<void> loadAlerts() async {
    isLoading = true;
    isError = false;
    notifyListeners();
    try {
      final alerts = await repository.getAlerts();
      allAlerts = alerts;
      lastSync = DateTime.now();
      connectionStatus = ConnectionStatus.connected;
      applyFilters();
    } catch (e) {
      isError = true;
      errorMessage = e.toString();
      connectionStatus = ConnectionStatus.offline;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void applyFilters() {
    List<AlertModel> list = List.from(allAlerts);
    if (viewMode == AlertViewMode.notifications) {
      list = list.where((a) => ['system', 'maintenance', 'firmware', 'device connected', 'device disconnected', 'acknowledged', 'resolved'].any((k) => a.alertType.toLowerCase().contains(k))).toList();
    } else {
      list = list.where((a) =>!['system', 'maintenance'].contains(a.alertType.toLowerCase())).toList();
    }
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list.where((a) => a.id.toLowerCase().contains(q) || a.incidentId.toLowerCase().contains(q) || a.fireId.toLowerCase().contains(q) || a.capsuleId.toLowerCase().contains(q) || a.location.toLowerCase().contains(q) || a.alertType.toLowerCase().contains(q)).toList();
    }
    if (statusFilter!= 'All') {
      if (statusFilter == 'Active') list = list.where((a) => a.status == AlertStatus.active).toList();
      if (statusFilter == 'Acknowledged') list = list.where((a) => a.status == AlertStatus.acknowledged).toList();
      if (statusFilter == 'Resolved') list = list.where((a) => a.status == AlertStatus.resolved).toList();
    }
    if (severityFilter!= 'All') {
      list = list.where((a) => a.severity.name.toLowerCase() == severityFilter.toLowerCase()).toList();
    }
    if (typeFilter!= 'All') {
      list = list.where((a) => a.alertType == typeFilter).toList();
    }
    if (locationFilter!= 'All') {
      list = list.where((a) => a.location.contains(locationFilter)).toList();
    }
    if (timeFilter!= 'All') {
      final now = DateTime.now();
      if (timeFilter == 'Today') list = list.where((a) => a.detectionTime.isAfter(DateTime(now.year, now.month, now.day))).toList();
      if (timeFilter == '24 hours') list = list.where((a) => a.detectionTime.isAfter(now.subtract(const Duration(hours: 24)))).toList();
      if (timeFilter == '7 days') list = list.where((a) => a.detectionTime.isAfter(now.subtract(const Duration(days: 7)))).toList();
    }
    list.sort((a, b) {
      if (sortBy == 'Oldest') return a.detectionTime.compareTo(b.detectionTime);
      if (sortBy == 'Highest severity') return a.severity.index.compareTo(b.severity.index);
      if (sortBy == 'Last updated') return b.lastUpdated.compareTo(a.lastUpdated);
      return b.detectionTime.compareTo(a.detectionTime);
    });
    filteredAlerts = list;
    notifyListeners();
  }

  void onRealtimeAlert(AlertModel realAlert) {
    final idx = allAlerts.indexWhere((a) => a.id == realAlert.id);
    if (idx >= 0) {
      allAlerts[idx] = realAlert;
    } else {
      allAlerts.insert(0, realAlert);
      highlightedId = realAlert.id;
    }
    lastSync = DateTime.now();
    applyFilters();
    Future.delayed(const Duration(seconds: 3), () {
      highlightedId = null;
      notifyListeners();
    });
  }
}

void main() => runApp(const FireGuardApp());

class FireGuardApp extends StatelessWidget {
  const FireGuardApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: FireColors.bg, useMaterial3: true),
        home: const FireGuardAlertsScreen(),
      );
}

class FireGuardAlertsScreen extends StatefulWidget {
  const FireGuardAlertsScreen({super.key});
  @override
  State<FireGuardAlertsScreen> createState() => _FireGuardAlertsScreenState();
}

class _FireGuardAlertsScreenState extends State<FireGuardAlertsScreen> with TickerProviderStateMixin {
  late AlertController _controller;
  final TextEditingController _searchCtrl = TextEditingController();
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  late AnimationController _pulse;
  bool _isDetailsOpen = false;
  bool _isVoiceOpen = false;
  bool _isListening = false;
  VoiceState _voiceState = VoiceState.idle;
  final List<Map<String, String>> _conversation = [];

  final FireGuardAiService _aiService = FireGuardAiService(baseUrl: FireGuardConfig.apiBaseUrl);
  FireGuardAiResult? _aiResult;
  bool _isAiAnalyzing = false;
  String? _aiError;

  @override
  void initState() {
    super.initState();

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();

    final api = AlertApiService(
      baseUrl: FireGuardConfig.apiBaseUrl,
    );

    final auth = AuthService();

    _controller = AlertController(
      repository: AlertRepository(
        api: api,
        auth: auth,
      ),
      api: api,
    );

    _controller.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    _controller.loadAlerts();

    // Initialize real speech recognition and voice output.
    _initSpeech();
    _initTts();

    _conversation.add({
      "role": "assistant",
      "text": "FireGuard Assistant ready. Ask me about alerts, sensors, fire risk, AI analysis, location, or NASA evidence.",
    });
  }

  // ===== STEP 1: _initSpeech() PASTED ABOVE _initTts() =====
  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onStatus: (status) {
        if (!mounted) {
          return;
        }
        if (status == 'notListening') {
          setState(() {
            _isListening = false;
            if (_voiceState == VoiceState.listening) {
              _voiceState = VoiceState.idle;
            }
          });
        }
      },
      onError: (error) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isListening = false;
          _voiceState = VoiceState.error;
        });
        debugPrint('Speech recognition error: $error');
      },
    );

    if (!mounted) {
      return;
    }

    if (!available) {
      setState(() {
        _isListening = false;
        _voiceState = VoiceState.error;
      });
    }
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.50);
    await _tts.setPitch(1.03);
    await _tts.setVolume(1.0);

    _tts.setStartHandler(() {
      if (!mounted) return;
      setState(() {
        _voiceState = VoiceState.speaking;
      });
    });

    _tts.setCompletionHandler(() {
      if (!mounted) return;
      setState(() {
        _voiceState = VoiceState.idle;
      });
    });

    _tts.setCancelHandler(() {
      if (!mounted) return;
      setState(() {
        _voiceState = VoiceState.idle;
      });
    });

    _tts.setErrorHandler((message) {
      if (!mounted) return;
      setState(() {
        _voiceState = VoiceState.error;
      });
      debugPrint('TTS ERROR: $message');
    });
  }

  Future<void> _speak(String text) async {
    if (text.trim().isEmpty) {
      return;
    }
    try {
      await _tts.stop();
      if (!mounted) {
        return;
      }
      setState(() {
        _voiceState = VoiceState.speaking;
      });
      await _tts.speak(text);
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _voiceState = VoiceState.error;
      });
      debugPrint('TTS ERROR: $e');
    }
  }

  Future<void> _analyzeSelectedAlert() async {
    final alert = _controller.selectedAlert;
    if (alert == null) return;
    if (alert.capsuleId.isEmpty) {
      setState(() {
        _aiResult = null;
        _aiError = 'This alert is not linked to a capsule.';
      });
      return;
    }
    setState(() {
      _isAiAnalyzing = true;
      _aiError = null;
    });
    try {
      final telemetry = await _controller.repository.getLatestTelemetry(alert.capsuleId);
      final temperature = (telemetry['temperature'] as num?)?.toDouble();
      final smokeLevel = (telemetry['smoke_level']?? telemetry['smokeLevel']) is num
         ? ((telemetry['smoke_level']?? telemetry['smokeLevel']) as num).toDouble()
          : null;
      final humidity = (telemetry['humidity'] as num?)?.toDouble();
      final windSpeed = (telemetry['wind_speed']?? telemetry['windSpeed']) is num
         ? ((telemetry['wind_speed']?? telemetry['windSpeed']) as num).toDouble()
          : null;
      final mq2 = (telemetry['mq2'] as num?)?.toDouble()?? 0.0;
      final mq7 = (telemetry['mq7'] as num?)?.toDouble()?? 0.0;
      final infraredTemperature = (telemetry['infrared_temperature']?? telemetry['infraredTemperature']) is num
         ? ((telemetry['infrared_temperature']?? telemetry['infraredTemperature']) as num).toDouble()
          : 0.0;
      final flameDetected = telemetry['flame_detected']?? telemetry['flameDetected']?? false;

      if (temperature == null || smokeLevel == null || humidity == null || windSpeed == null) {
        throw Exception('Required real telemetry is missing. Temperature, smoke, humidity and wind speed are required.');
      }

      final result = await _aiService.analyzeAlert(
        temperature: temperature,
        smokeLevel: smokeLevel,
        humidity: humidity,
        windSpeed: windSpeed,
        mq2: mq2,
        mq7: mq7,
        infraredTemperature: infraredTemperature,
        flameDetected: flameDetected == true,
      );

      if (!mounted) return;
      setState(() {
        _aiResult = result;
        _isAiAnalyzing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAiAnalyzing = false;
        _aiError = 'AI analysis failed: $e';
      });
    }
  }

  Widget _buildAiResultCard(FireGuardAiResult result) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.35)),
        color: Colors.orange.withOpacity(0.06),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.psychology, color: Colors.orange),
            SizedBox(width: 8),
            Expanded(child: Text('FireGuard AI Analysis', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
          ]),
          const SizedBox(height: 16),
          _detailRow('Classification', result.classification),
          _detailRow('Confidence', '${result.confidence.toStringAsFixed(2)}%'),
          _detailRow('Risk Score', '${result.riskScore}/100'),
          _detailRow('Severity', result.severity),
          _detailRow('Flame Detected', result.flameDetected? 'YES' : 'NO'),
          _detailRow('Critical Conditions', result.criticalConditions.toString()),
          _detailRow('Elevated Conditions', result.elevatedConditions.toString()),
          const SizedBox(height: 12),
          const Text('AI Explanation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 6),
          Text(result.explanation, style: const TextStyle(fontSize: 13, height: 1.4)),
          if (result.sensorStatus.isNotEmpty)...[
            const SizedBox(height: 14),
            const Text('Sensor Assessment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
           ...result.sensorStatus.entries.map((entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(children: [
                    Expanded(child: Text(entry.key, style: const TextStyle(fontSize: 13))),
                    Text(entry.value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ]),
                )),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    _searchCtrl.dispose();
    _speech.cancel();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final isMobile = w < 768;
      final isTablet = w >= 768 && w < 1200;
      final isDesktop = w >= 1200;
      return Scaffold(
        backgroundColor: FireColors.bg,
        body: Row(children: [
          if (!isMobile) _buildSidebar(isTablet),
          Expanded(
              child: Stack(children: [
            Column(children: [
              _buildHeader(isMobile),
              _buildConnectionBar(),
              _buildTabs(),
              Expanded(
                  child: Padding(
                      padding: EdgeInsets.all(isMobile? 16 : 24),
                      child: Column(children: [
                        _buildSummaryCards(isMobile, isTablet),
                        const SizedBox(height: 20),
                        _buildFilterBar(isMobile),
                        const SizedBox(height: 20),
                        Expanded(child: _buildMainContent(isMobile, isDesktop)),
                      ]))),
            ]),
            Positioned(right: isMobile? 16 : 24, bottom: isMobile? 88 : 24, child: _buildVoiceButton()),
            if (_isVoiceOpen) _buildVoicePanel(isMobile),
          ])),
        ]),
        bottomNavigationBar: isMobile? _buildBottomNav() : null,
      );
    });
  }

  Widget _buildHeader(bool isMobile) => Container(
      height: isMobile? 56 : 72,
      padding: EdgeInsets.symmetric(horizontal: isMobile? 16 : 24),
      decoration: const BoxDecoration(color: FireColors.bg, border: Border(bottom: BorderSide(color: FireColors.border))),
      child: Row(children: [
        Expanded(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("Alerts & Notifications", style: TextStyle(color: FireColors.primaryText, fontSize: 20, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text("System monitoring active • ${_controller.filteredAlerts.length} total • ${_controller.allAlerts.where((a) => a.isUnread).length} unread",
              style: const TextStyle(color: FireColors.secondaryText, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
        if (!isMobile)...[
          Container(
              width: 300,
              height: 40,
              decoration: BoxDecoration(color: FireColors.cardBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: FireColors.border)),
              child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) {
                    _controller.searchQuery = v;
                    _controller.applyFilters();
                  },
                  style: const TextStyle(color: FireColors.primaryText, fontSize: 13),
                  decoration: const InputDecoration(
                      hintText: "Search Alert ID, Incident, Fire, Capsule, Location, Type",
                      hintStyle: TextStyle(color: FireColors.secondaryText, fontSize: 11),
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.search, size: 18, color: FireColors.secondaryText)))),
          const SizedBox(width: 8),
          _iconBtn(Icons.refresh_rounded, 40, onTap: _controller.loadAlerts),
          const SizedBox(width: 8),
          _iconBtn(Icons.settings_outlined, 40, onTap: () {}),
          const SizedBox(width: 8),
          _iconBtn(Icons.person_outline_rounded, 40, onTap: () {}),
        ]
      ]));

  Widget _buildConnectionBar() => Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      color: FireColors.cardBg,
      child: Row(children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: _controller.connectionStatus == ConnectionStatus.connected? FireColors.operational : _controller.connectionStatus == ConnectionStatus.reconnecting? FireColors.warning : FireColors.critical)),
        const SizedBox(width: 8),
        Text(_controller.connectionStatus == ConnectionStatus.connected? "Connected" : _controller.connectionStatus == ConnectionStatus.reconnecting? "Reconnecting" : "Offline",
            style: TextStyle(fontSize: 12, color: _controller.connectionStatus == ConnectionStatus.connected? FireColors.operational : _controller.connectionStatus == ConnectionStatus.reconnecting? FireColors.warning : FireColors.critical)),
        const SizedBox(width: 16),
        Text(_controller.lastSync!= null? "Last sync: ${DateFormat('HH:mm:ss').format(_controller.lastSync!)}" : "Last sync: --:--:--", style: const TextStyle(fontSize: 12, color: FireColors.secondaryText)),
        const Spacer(),
        if (_controller.connectionStatus!= ConnectionStatus.connected)
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: FireColors.critical.withOpacity(0.15), borderRadius: BorderRadius.circular(6)), child: const Text("Realtime connection lost — reconnecting...", style: TextStyle(fontSize: 10, color: FireColors.critical))),
      ]));

  Widget _buildTabs() => Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: FireColors.border))),
      child: Row(children: [
        _tab("Alerts", _controller.viewMode == AlertViewMode.alerts, () => setState(() {
              _controller.viewMode = AlertViewMode.alerts;
              _controller.applyFilters();
            })),
        const SizedBox(width: 24),
        _tab("Notifications", _controller.viewMode == AlertViewMode.notifications, () => setState(() {
              _controller.viewMode = AlertViewMode.notifications;
              _controller.applyFilters();
            })),
      ]));

  Widget _tab(String label, bool active, VoidCallback onTap) => InkWell(
      onTap: onTap,
      child: Container(padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(border: Border(bottom: BorderSide(color: active? FireColors.info : Colors.transparent, width: 2))), child: Text(label, style: TextStyle(color: active? FireColors.primaryText : FireColors.secondaryText, fontSize: 14, fontWeight: active? FontWeight.w600 : FontWeight.w400))));

  Widget _buildSummaryCards(bool isMobile, bool isTablet) {
    final critical = _controller.allAlerts.where((a) => a.severity == AlertSeverity.critical && a.status!= AlertStatus.resolved).length;
    final warning = _controller.allAlerts.where((a) => a.severity == AlertSeverity.warning && a.status!= AlertStatus.resolved).length;
    final active = _controller.allAlerts.where((a) => a.status == AlertStatus.active).length;
    final unread = _controller.allAlerts.where((a) => a.isUnread).length;
    final cards = [
      {"label": "CRITICAL", "value": "$critical", "color": FireColors.critical, "icon": Icons.local_fire_department_rounded},
      {"label": "WARNING", "value": "$warning", "color": FireColors.warning, "icon": Icons.warning_amber_rounded},
      {"label": "ACTIVE", "value": "$active", "color": FireColors.operational, "icon": Icons.notifications_active_rounded},
      {"label": "UNREAD", "value": "$unread", "color": FireColors.info, "icon": Icons.mark_email_unread_rounded},
    ];
    if (isMobile) {
      return SizedBox(height: 104, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: 4, separatorBuilder: (_, __) => const SizedBox(width: 12), itemBuilder: (_, i) => SizedBox(width: 170, child: _summaryCard(cards[i]))));
    }
    return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: isTablet? 2 : 4, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 2.9),
        itemCount: 4,
        itemBuilder: (_, i) => _summaryCard(cards[i]));
  }

  Widget _summaryCard(Map<String, dynamic> d) => Container(
      height: 98,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: FireColors.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: FireColors.border)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: (d["color"] as Color).withOpacity(0.15), borderRadius: BorderRadius.circular(8)), child: Icon(d["icon"] as IconData, size: 20, color: d["color"] as Color)),
        const SizedBox(width: 12),
        Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(d["value"] as String, style: const TextStyle(color: FireColors.primaryText, fontSize: 28, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Flexible(child: Text(d["label"] as String, style: const TextStyle(color: FireColors.secondaryText, fontSize: 12, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
          const SizedBox(height: 2),
          const Text("Active incidents", style: TextStyle(color: FireColors.secondaryText, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
      ]));

  Widget _buildFilterBar(bool isMobile) => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: FireColors.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: FireColors.border)),
      child: isMobile
         ? Column(children: [
              Row(children: [
                _filterDropdown("Status", ["All", "Active", "Acknowledged", "Resolved"], _controller.statusFilter, (v) {
                  _controller.statusFilter = v;
                  _controller.applyFilters();
                }),
                const SizedBox(width: 8),
                _filterDropdown("Severity", ["All", "Critical", "Warning", "Info"], _controller.severityFilter, (v) {
                  _controller.severityFilter = v;
                  _controller.applyFilters();
                }),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                _filterDropdown("Type", ["All", "Fire Detected", "Smoke", "High Temperature", "Device Fault", "Communication", "Power", "Suppression"], _controller.typeFilter, (v) {
                  _controller.typeFilter = v;
                  _controller.applyFilters();
                }),
                const SizedBox(width: 8),
                _filterDropdown("Time", ["All", "Today", "24 hours", "7 days", "30 days"], _controller.timeFilter, (v) {
                  _controller.timeFilter = v;
                  _controller.applyFilters();
                }),
              ]),
            ])
          : Row(children: [
              const Icon(Icons.tune_rounded, size: 18, color: FireColors.secondaryText),
              const SizedBox(width: 8),
              _filterDropdown("Status", ["All", "Active", "Acknowledged", "Resolved"], _controller.statusFilter, (v) {
                _controller.statusFilter = v;
                _controller.applyFilters();
              }),
              const SizedBox(width: 8),
              _filterDropdown("Severity", ["All", "Critical", "Warning", "Info"], _controller.severityFilter, (v) {
                _controller.severityFilter = v;
                _controller.applyFilters();
              }),
              const SizedBox(width: 8),
              _filterDropdown("Type", ["All", "Fire Detected", "Smoke", "High Temperature", "Device Fault", "Communication", "Power", "Suppression"], _controller.typeFilter, (v) {
                _controller.typeFilter = v;
                _controller.applyFilters();
              }),
              const SizedBox(width: 8),
              _filterDropdown("Location", ["All", "Maun North", "Okavango", "Central"], _controller.locationFilter, (v) {
                _controller.locationFilter = v;
                _controller.applyFilters();
              }),
              const SizedBox(width: 8),
              _filterDropdown("Time", ["All", "Today", "24 hours", "7 days", "30 days"], _controller.timeFilter, (v) {
                _controller.timeFilter = v;
                _controller.applyFilters();
              }),
              const Spacer(),
              DropdownButton<String>(
                  value: _controller.sortBy,
                  underline: const SizedBox(),
                  dropdownColor: FireColors.drawerBg,
                  style: const TextStyle(color: FireColors.primaryText, fontSize: 12),
                  items: ["Newest", "Oldest", "Highest severity", "Last updated"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) {
                    setState(() {
                      _controller.sortBy = v!;
                      _controller.applyFilters();
                    });
                  }),
            ]));

  Widget _filterDropdown(String hint, List<String> opts, String value, Function(String) onChanged) => Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: FireColors.bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: FireColors.border)),
      child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
              value: value,
              hint: Text(hint, style: const TextStyle(fontSize: 12)),
              dropdownColor: FireColors.drawerBg,
              style: const TextStyle(color: FireColors.primaryText, fontSize: 12),
              items: opts.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12)))).toList(),
              onChanged: (v) {
                if (v!= null) onChanged(v);
              })));

  Widget _buildMainContent(bool isMobile, bool isDesktop) {
    if (_controller.isLoading) return _buildSkeleton();
    if (_controller.isError) return _buildErrorState();
    if (_controller.filteredAlerts.isEmpty) return _buildEmptyState();
    if (isMobile) return _buildAlertList();
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(flex: _isDetailsOpen? 6 : 10, child: _buildAlertList()),
      if (_isDetailsOpen)...[const SizedBox(width: 16), _buildDetailsPanel()],
    ]);
  }

  Widget _buildSkeleton() => ListView.separated(
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Container(height: 104, decoration: BoxDecoration(color: FireColors.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: FireColors.border))));

  Widget _buildErrorState() => Container(
      decoration: BoxDecoration(color: FireColors.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: FireColors.border)),
      child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.cloud_off_rounded, size: 48, color: FireColors.secondaryText),
        const SizedBox(height: 12),
        const Text("Unable to load alerts", style: TextStyle(color: FireColors.primaryText, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text("Error: ${_controller.errorMessage?? 'FireGuard backend is unavailable.'}", style: const TextStyle(color: FireColors.secondaryText, fontSize: 13)),
        const SizedBox(height: 16),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: FireColors.info), onPressed: _controller.loadAlerts, child: const Text("Retry")),
      ])));

  Widget _buildEmptyState() => Container(
      decoration: BoxDecoration(color: FireColors.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: FireColors.border)),
      child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.notifications_none_rounded, size: 48, color: FireColors.secondaryText),
        const SizedBox(height: 12),
        Text(_controller.viewMode == AlertViewMode.alerts? "No active alerts" : "No notifications", style: const TextStyle(color: FireColors.primaryText, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        const Text("FireGuard is monitoring connected systems.", style: TextStyle(color: FireColors.secondaryText, fontSize: 13)),
        const SizedBox(height: 12),
        Text("System monitoring: ACTIVE • Backend: ${_controller.connectionStatus.name.toUpperCase()} • Last sync: ${_controller.lastSync!= null? DateFormat('HH:mm:ss').format(_controller.lastSync!) : '--:--:--'}", style: const TextStyle(color: FireColors.secondaryText, fontSize: 11)),
      ])));

  Widget _buildAlertList() => ListView.separated(
      itemCount: _controller.filteredAlerts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final a = _controller.filteredAlerts[i];
        final isSelected = _controller.selectedAlert?.id == a.id;
        final isHighlighted = _controller.highlightedId == a.id;
        return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(color: isSelected? FireColors.drawerBg : FireColors.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: isHighlighted? FireColors.info : isSelected? FireColors.info.withOpacity(0.5) : FireColors.border)),
            child: InkWell(
                onTap: () {
                  setState(() {
                    _controller.selectedAlert = a;
                    _isDetailsOpen = true;
                    a.isUnread = false;
                    _aiResult = null;
                    _aiError = null;
                  });
                },
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: _severityColor(a.severity), shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Flexible(child: Text(a.severity.name.toUpperCase(), style: TextStyle(color: _severityColor(a.severity), fontSize: 11, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 8),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: _statusColor(a.status).withOpacity(0.15), borderRadius: BorderRadius.circular(6)), child: Text(a.status.name.toUpperCase(), style: TextStyle(color: _statusColor(a.status), fontSize: 10, fontWeight: FontWeight.w600))),
                        const Spacer(),
                        Text(_timeAgo(a.detectionTime), style: const TextStyle(color: FireColors.secondaryText, fontSize: 11)),
                      ]),
                      const SizedBox(height: 8),
                      Text(a.title, style: const TextStyle(color: FireColors.primaryText, fontSize: 14, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Row(children: [
                        const Icon(Icons.location_on_rounded, size: 12, color: FireColors.secondaryText),
                        const SizedBox(width: 4),
                        Expanded(child: Text("${a.location} • ${a.capsuleId} • ${a.incidentId}", style: const TextStyle(color: FireColors.secondaryText, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis))
                      ]),
                      const SizedBox(height: 6),
                      Row(children: [
                        if (a.evidence.temperature!= null) Text("Temp ${a.evidence.temperature}°C", style: const TextStyle(color: FireColors.secondaryText, fontSize: 11)),
                        if (a.evidence.aiConfidence!= null)...[
                          const SizedBox(width: 12),
                          Text("AI ${a.evidence.aiConfidence?.toStringAsFixed(0)}%", style: const TextStyle(color: FireColors.secondaryText, fontSize: 11)),
                        ],
                        const Spacer(),
                        const Text("View →", style: TextStyle(color: FireColors.info, fontSize: 11)),
                      ]),
                    ]))));
      });

  Widget _buildDetailsPanel() {
    final a = _controller.selectedAlert!;
    return Container(
        width: 420,
        constraints: const BoxConstraints(maxWidth: 460, minWidth: 380),
        decoration: BoxDecoration(color: FireColors.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: FireColors.border)),
        child: Column(children: [
          Padding(padding: const EdgeInsets.all(20), child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a.severity.name.toUpperCase(), style: TextStyle(color: _severityColor(a.severity), fontSize: 11, fontWeight: FontWeight.w700)),
              Text(a.title, style: const TextStyle(color: FireColors.primaryText, fontSize: 16, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
              Text("Incident ${a.incidentId} • ${a.id}", style: const TextStyle(color: FireColors.secondaryText, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
            IconButton(onPressed: () => setState(() => _isDetailsOpen = false), icon: const Icon(Icons.close_rounded, size: 20))
          ])),
          Expanded(
              child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _sectionTitle("Incident Information"),
                    _detailRow("Alert ID", a.id),
                    _detailRow("Incident ID", a.incidentId),
                    _detailRow("Fire ID", a.fireId),
                    _detailRow("Capsule ID", a.capsuleId),
                    _detailRow("Alert Type", a.alertType),
                    _detailRow("Status", a.status.name.toUpperCase()),
                    const SizedBox(height: 20),
                    _sectionTitle("Location"),
                    _detailRow("Location", a.location),
                    _detailRow("Latitude", a.latitude?.toString()?? "--"),
                    _detailRow("Longitude", a.longitude?.toString()?? "--"),
                    const SizedBox(height: 12),
                    SizedBox(width: double.infinity, height: 40, child: OutlinedButton.icon(icon: const Icon(Icons.map_rounded, size: 18), label: const Text("View on Map"), onPressed: () {})),
                    const SizedBox(height: 20),
                    _sectionTitle("Detection & AI Verification"),
                    if (a.evidence.aiVerification!= null) _detailRow("AI Verification", a.evidence.aiVerification!),
                    if (a.evidence.aiConfidence!= null) _detailRow("AI Confidence", "${a.evidence.aiConfidence}%"),
                    if (a.evidence.fireClassification!= null) _detailRow("Classification", a.evidence.fireClassification!),
                    _detailRow("Detection Time", DateFormat('yyyy-MM-dd HH:mm:ss').format(a.detectionTime)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: FireColors.info, foregroundColor: Colors.white),
                        onPressed: _isAiAnalyzing? null : _analyzeSelectedAlert,
                        icon: _isAiAnalyzing? const SizedBox(width: 17, height: 17, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.auto_awesome_rounded, size: 19),
                        label: Text(_isAiAnalyzing? 'Analyzing with FireGuard AI...' : 'Run FireGuard AI Analysis'),
                      ),
                    ),
                    if (_aiError!= null)...[const SizedBox(height: 10), Text(_aiError!, style: const TextStyle(color: Colors.red, fontSize: 13))],
                    if (_aiResult!= null)...[const SizedBox(height: 14), _buildAiResultCard(_aiResult!)],
                    const SizedBox(height: 20),
                    _sectionTitle("Environmental Evidence"),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      if (a.evidence.temperature!= null) _metricCard("Temperature", "${a.evidence.temperature}°C"),
                      if (a.evidence.smokeLevel!= null) _metricCard("Smoke", "${a.evidence.smokeLevel}%"),
                      if (a.evidence.humidity!= null) _metricCard("Humidity", "${a.evidence.humidity}%"),
                      if (a.evidence.windSpeed!= null) _metricCard("Wind", "${a.evidence.windSpeed} m/s"),
                    ]),
                    const SizedBox(height: 20),
                    _sectionTitle("Capsule Health"),
                    if (a.evidence.battery!= null) _detailRow("Battery", "${a.evidence.battery}%"),
                    _detailRow("Solar", a.evidence.solarStatus?? "--"),
                    _detailRow("Network", a.evidence.networkStatus?? "--"),
                    _detailRow("Device Status", a.evidence.deviceStatus?? "--"),
                    _detailRow("Last Comm", a.lastCommunication!= null? DateFormat('HH:mm:ss').format(a.lastCommunication!) : "--"),
                    const SizedBox(height: 20),
                    _sectionTitle("Response"),
                    _detailRow("Response", a.responseStatus?? "--"),
                    _detailRow("Suppression", a.suppressionStatus?? "--"),
                    _detailRow("Activation", a.responseActivationTime!= null? DateFormat('HH:mm:ss').format(a.responseActivationTime!) : "--"),
                    _detailRow("Incident Status", a.incidentStatus?? "Open"),
                    const SizedBox(height: 20),
                    _sectionTitle("Incident Timeline"),
                   ...a.timeline.map((t) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(DateFormat('HH:mm').format(t.time), style: const TextStyle(color: FireColors.secondaryText, fontSize: 11)),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(t.description, style: const TextStyle(color: FireColors.primaryText, fontSize: 12)),
                            Text("${t.source} • ${t.status}", style: const TextStyle(color: FireColors.secondaryText, fontSize: 10)),
                          ]))
                        ]))),
                    const SizedBox(height: 80),
                  ]))),
          Padding(padding: const EdgeInsets.all(20), child: _buildActions(a)),
        ]));
  }

  Widget _buildActions(AlertModel a) {
    if (a.status == AlertStatus.active) {
      return Column(children: [
        SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: FireColors.info, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                onPressed: () async {
                  try {
                    await _controller.repository.acknowledgeAlert(a.id);
                    setState(() {
                      a.status = AlertStatus.acknowledged;
                      a.acknowledgedAt = DateTime.now();
                      a.lastUpdated = DateTime.now();
                    });
                    _controller.applyFilters();
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Acknowledge failed: $e")));
                  }
                },
                child: const Text("Acknowledge", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)))),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.map_rounded, size: 16), onPressed: () {}, label: const Text("Open Map", style: TextStyle(fontSize: 12)))),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.assignment_rounded, size: 16), onPressed: () {}, label: const Text("View Incident", style: TextStyle(fontSize: 12)))),
        ]),
      ]);
    }
    if (a.status == AlertStatus.acknowledged) {
      return Column(children: [
        SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: FireColors.info, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                onPressed: () => _confirmResolve(a),
                child: const Text("Resolve Alert", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)))),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.map_rounded, size: 16), onPressed: () {}, label: const Text("Open Map", style: TextStyle(fontSize: 12)))),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.assignment_rounded, size: 16), onPressed: () {}, label: const Text("View Incident", style: TextStyle(fontSize: 12)))),
        ]),
      ]);
    }
    return SizedBox(width: double.infinity, height: 44, child: OutlinedButton.icon(icon: const Icon(Icons.history_rounded, size: 16), onPressed: () {}, label: const Text("View History")));
  }

  void _confirmResolve(AlertModel a) => showDialog(
      context: context,
      builder: (_) => AlertDialog(
          backgroundColor: FireColors.cardBg,
          title: const Text("Confirm Resolution?", style: TextStyle(color: FireColors.primaryText, fontSize: 14)),
          content: Text("Resolve ${a.id} - ${a.incidentId}? This is audited.", style: const TextStyle(color: FireColors.secondaryText, fontSize: 12)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: FireColors.info),
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await _controller.repository.resolveAlert(a.id);
                    setState(() {
                      a.status = AlertStatus.resolved;
                      a.resolvedAt = DateTime.now();
                      a.lastUpdated = DateTime.now();
                    });
                    _controller.applyFilters();
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Resolve failed: $e")));
                  }
                },
                child: const Text("Confirm")),
          ]));

  Widget _buildVoiceButton() => Tooltip(
      message: "Voice Assistant",
      child: GestureDetector(
          onTap: () => setState(() => _isVoiceOpen =!_isVoiceOpen),
          child: AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) {
                final listening = _voiceState == VoiceState.listening;
                return Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: listening? FireColors.info.withOpacity(0.2) : FireColors.drawerBg,
                        border: Border.all(color: listening? FireColors.info : FireColors.border),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12)]),
                    child: Stack(alignment: Alignment.center, children: [
                      if (listening) Container(width: 52 + 12 * _pulse.value, height: 52 + 12 * _pulse.value, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: FireColors.info.withOpacity(0.5)))),
                      Icon(Icons.mic_rounded, size: 22, color: listening? FireColors.info : FireColors.primaryText)
                    ]));
              })));

  // ===== FIXED VOICE PANEL - NO SYNTAX ERRORS =====
  Widget _buildVoicePanel(bool isMobile) {
    final w = isMobile? MediaQuery.of(context).size.width : 360.0;
    final h = isMobile? MediaQuery.of(context).size.height * 0.6 : 480.0;

    return Positioned(
      right: isMobile? 0 : 24,
      bottom: isMobile? 72 : 88,
      child: Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: FireColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: FireColors.border),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20)],
        ),
        child: Column(
          children: [
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: FireColors.border))),
              child: Row(
                children: [
                  const Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text("FIREGUARD Assistant", style: TextStyle(color: FireColors.primaryText, fontSize: 14, fontWeight: FontWeight.w700)),
                    Text("Voice & Alert Assistant", style: TextStyle(color: FireColors.secondaryText, fontSize: 11)),
                  ]),
                  const Spacer(),
                  IconButton(onPressed: () => setState(() => _isVoiceOpen = false), icon: const Icon(Icons.close_rounded, size: 18)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _conversation.length,
                itemBuilder: (_, i) {
                  final message = _conversation[i];
                  final isOperator = message['role'] == 'operator';
                  return Align(
                    alignment: isOperator? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      constraints: BoxConstraints(maxWidth: w * 0.8),
                      decoration: BoxDecoration(
                        color: isOperator? FireColors.drawerBg : FireColors.bg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: FireColors.border),
                      ),
                      child: Text(message['text']?? '', style: const TextStyle(color: FireColors.primaryText, fontSize: 12.5)),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: FireColors.border))),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(color: FireColors.info, shape: BoxShape.circle),
                    child: IconButton(
                      icon: Icon(_voiceState == VoiceState.listening? Icons.stop_rounded : Icons.mic_rounded, color: Colors.white, size: 20),
                      onPressed: () async {
                        if (_voiceState == VoiceState.listening) {
                          await _speech.stop();
                          if (!mounted) return;
                          setState(() {
                            _isListening = false;
                            _voiceState = VoiceState.idle;
                          });
                        } else {
                          bool available = await _speech.initialize();
                          if (!available) return;
                          setState(() {
                            _isListening = true;
                            _voiceState = VoiceState.listening;
                          });
                          await _speech.listen(onResult: (r) {
                            if (r.finalResult) {
                              _processVoice(r.recognizedWords);
                            }
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_voiceState == VoiceState.listening? "Listening..." : _voiceState == VoiceState.processing? "Processing..." : _voiceState == VoiceState.speaking? "Speaking..." : "Tap to speak",
                        style: const TextStyle(color: FireColors.secondaryText, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processVoice(String input) async {
    final text = input.trim();
    if (text.isEmpty) {
      setState(() => _voiceState = VoiceState.idle);
      return;
    }
    // Persistent conversation
    setState(() {
      _conversation.add({"role": "operator", "text": text});
      _voiceState = VoiceState.processing;
      _isListening = false;
    });
    try {
      final selected = _controller.selectedAlert;
      final alertContext = selected == null
         ? <String, dynamic>{}
          : {
              "alertId": selected.id,
              "incidentId": selected.incidentId,
              "fireId": selected.fireId,
              "capsuleId": selected.capsuleId,
              "title": selected.title,
              "severity": selected.severity.name,
              "status": selected.status.name,
              "alertType": selected.alertType,
              "location": selected.location,
              "latitude": selected.latitude,
              "longitude": selected.longitude,
              "temperature": selected.evidence.temperature,
              "smokeLevel": selected.evidence.smokeLevel,
              "humidity": selected.evidence.humidity,
              "windSpeed": selected.evidence.windSpeed,
              "battery": selected.evidence.battery,
              "aiConfidence": selected.evidence.aiConfidence,
              "aiVerification": selected.evidence.aiVerification,
              "fireClassification": selected.evidence.fireClassification
            };
      final response = await http
         .post(Uri.parse('${FireGuardConfig.apiBaseUrl}/api/ai/assistant'),
              headers: {'Content-Type': 'application/json'}, body: jsonEncode({"message": text, "alert_context": alertContext}))
         .timeout(FireGuardConfig.apiTimeout);
      if (response.statusCode!= 200) throw Exception("AI request failed: ${response.statusCode}");
      final data = jsonDecode(response.body);
      final aiResponse = data["response"]?.toString()?? "The AI did not return a response.";
      setState(() {
        _conversation.add({"role": "assistant", "text": aiResponse});
      });
      await _speak(aiResponse);
    } catch (e) {
      const errorMessage = "I could not connect to the FireGuard AI service. Please check the backend.";
      setState(() {
        _conversation.add({"role": "assistant", "text": errorMessage});
        _voiceState = VoiceState.error;
      });
      await _speak(errorMessage);
      debugPrint("AI ERROR: $e");
    }
  }

  Widget _buildSidebar(bool compact) {
    final w = compact? 72.0 : 240.0;
    return Container(
        width: w,
        color: FireColors.cardBg,
        child: Column(children: [
          const SizedBox(height: 20),
          Container(width: 32, height: 32, decoration: BoxDecoration(color: FireColors.info, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.local_fire_department_rounded, size: 20, color: Colors.white)),
          const SizedBox(height: 32),
          _sideItem(Icons.dashboard_rounded, "Dashboard", false, compact),
          _sideItem(Icons.notifications_active_rounded, "Alerts", _controller.viewMode == AlertViewMode.alerts, compact, onTap: () {
            setState(() {
              _controller.viewMode = AlertViewMode.alerts;
              _controller.applyFilters();
            });
          }),
          _sideItem(Icons.notifications_none_rounded, "Notifications", _controller.viewMode == AlertViewMode.notifications, compact, onTap: () {
            setState(() {
              _controller.viewMode = AlertViewMode.notifications;
              _controller.applyFilters();
            });
          }),
          _sideItem(Icons.map_rounded, "Map", false, compact),
          _sideItem(Icons.assignment_rounded, "Incidents", false, compact),
        ]));
  }

  Widget _sideItem(IconData icon, String label, bool active, bool compact, {VoidCallback? onTap}) => InkWell(
      onTap: onTap,
      child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          height: 48,
          decoration: BoxDecoration(color: active? FireColors.drawerBg : Colors.transparent, borderRadius: BorderRadius.circular(10)),
          padding: EdgeInsets.symmetric(horizontal: compact? 0 : 16),
          child: Row(mainAxisAlignment: compact? MainAxisAlignment.center : MainAxisAlignment.start, children: [
            Icon(icon, color: active? FireColors.info : FireColors.secondaryText, size: 20),
            if (!compact)...[const SizedBox(width: 12), Expanded(child: Text(label, style: TextStyle(color: active? FireColors.primaryText : FireColors.secondaryText, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis))]
          ])));

  Widget _buildBottomNav() => Container(
      height: 68,
      decoration: const BoxDecoration(color: FireColors.cardBg, border: Border(top: BorderSide(color: FireColors.border))),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        const Icon(Icons.dashboard_rounded, color: FireColors.secondaryText),
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: FireColors.drawerBg, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.notifications_active_rounded, color: FireColors.info, size: 22)),
        const Icon(Icons.map_rounded, color: FireColors.secondaryText),
        const Icon(Icons.person_outline_rounded, color: FireColors.secondaryText),
      ]));

  Widget _iconBtn(IconData icon, double size, {required VoidCallback onTap}) => InkWell(
      onTap: onTap,
      child: Container(width: size, height: size, decoration: BoxDecoration(color: FireColors.cardBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: FireColors.border)), child: Icon(icon, size: 18, color: FireColors.primaryText)));

  Widget _sectionTitle(String t) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(t, style: const TextStyle(color: FireColors.primaryText, fontSize: 13, fontWeight: FontWeight.w600)));
  Widget _detailRow(String l, String v) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l, style: const TextStyle(color: FireColors.secondaryText, fontSize: 12)), const SizedBox(width: 16), Flexible(child: Text(v, textAlign: TextAlign.right, style: const TextStyle(color: FireColors.primaryText, fontSize: 12, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis))]));
  Widget _metricCard(String l, String v) => Container(width: 120, height: 64, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: FireColors.drawerBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: FireColors.border)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(l, style: const TextStyle(color: FireColors.secondaryText, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis), const Spacer(), Text(v, style: const TextStyle(color: FireColors.primaryText, fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)]));
  Color _severityColor(AlertSeverity s) => s == AlertSeverity.critical? FireColors.critical : s == AlertSeverity.warning? FireColors.warning : FireColors.info;
  Color _statusColor(AlertStatus s) => s == AlertStatus.active? FireColors.critical : s == AlertStatus.acknowledged? FireColors.warning : FireColors.operational;
  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 60) return "${d.inMinutes}m ago";
    if (d.inHours < 24) return "${d.inHours}h ago";
    return "${d.inDays}d ago";
  }
}