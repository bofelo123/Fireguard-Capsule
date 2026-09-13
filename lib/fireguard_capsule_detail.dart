import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

// Import Dashboard to navigate back - ADDED FOR NAVIGATION ONLY
import 'fireguard_dashboard_complete.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FireGuardApp());
}

class FireGuardApp extends StatelessWidget {
  const FireGuardApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FireGuard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: FGColors.background,
        fontFamily: 'Inter',
      ),
      home: const FireGuardCapsuleDetailScreen(capsuleId: 'CAP-001'),
    );
  }
}

// ============================================================
// COLOR SYSTEM - Strict FireGuard Palette
// ============================================================
class FGColors {
  static const background = Color(0xFF07111F);
  static const panel = Color(0xFF0D1B2A);
  static const elevated = Color(0xFF13263A);
  static const border = Color(0xFF1B3045);
  static const primaryText = Color(0xFFF5F7FA);
  static const secondaryText = Color(0xFF8FA3B8);
  static const healthy = Color(0xFF25C281);
  static const warning = Color(0xFFFFB547);
  static const critical = Color(0xFFFF4D3D);
  static const info = Color(0xFF4DA3FF);
}

// ============================================================
// ENUMS
// ============================================================
enum CapsuleOperationalState { operational, warning, critical, offline }

enum SensorSystemState { normal, elevated, critical, noData, fault }

enum VerificationState { monitoring, suspected, verified, failed }

enum ResponseStageState { pending, active, completed, failed }

enum SuppressionState { ready, active, completed, fault }

enum CommState { online, degraded, offline }

enum RelayState { on, off, unknown }

enum PowerSource { solar, battery, unknown }

enum Severity { info, warning, error, critical, success }

// ============================================================
// REAL DATA MODELS - No mock values
// ============================================================
class CapsuleIdentity {
  final String capsuleId;
  final String name;
  final String installationLocation;
  final CapsuleOperationalState operationalState;
  final DateTime? lastCommunication;
  final DateTime? lastSensorUpdate;
  const CapsuleIdentity({
    required this.capsuleId,
    required this.name,
    required this.installationLocation,
    required this.operationalState,
    this.lastCommunication,
    this.lastSensorUpdate,
  });
}

class SensorReading {
  final String
      sensorId; // stable id: flame_sensor, mq2, mq7, temperature, humidity, mlx90614
  final String sensorName;
  final IconData icon;
  final String? value;
  final String? unit;
  final String? displayState;
  final SensorSystemState systemState;
  final DateTime? timestamp;
  const SensorReading({
    required this.sensorId,
    required this.sensorName,
    required this.icon,
    this.value,
    this.unit,
    this.displayState,
    required this.systemState,
    this.timestamp,
  });
}

class FireVerificationData {
  final VerificationState state;
  final DateTime? verificationTime;
  final String? detectionSource;
  final String? aiStatus;
  final double? confidenceScore;
  final Map<String, SensorSystemState> evidence;
  const FireVerificationData({
    required this.state,
    this.verificationTime,
    this.detectionSource,
    this.aiStatus,
    this.confidenceScore,
    required this.evidence,
  });
}

class AutonomousResponseStage {
  final String id;
  final String name;
  final IconData icon;
  final ResponseStageState state;
  final DateTime? completedAt;
  const AutonomousResponseStage({
    required this.id,
    required this.name,
    required this.icon,
    required this.state,
    this.completedAt,
  });
}

class DeviceComponentHealth {
  final String componentName;
  final SensorSystemState status;
  final DateTime? lastDiagnostic;
  final DateTime? lastCommunication;
  final String? diagnosticResult;
  const DeviceComponentHealth({
    required this.componentName,
    required this.status,
    this.lastDiagnostic,
    this.lastCommunication,
    this.diagnosticResult,
  });
}

class PowerStatus {
  final double? batteryPercent;
  final String? batteryHealth;
  final bool? solarCharging;
  final PowerSource powerSource;
  final String? chargingState;
  final DateTime? lastPowerUpdate;
  const PowerStatus({
    this.batteryPercent,
    this.batteryHealth,
    this.solarCharging,
    required this.powerSource,
    this.chargingState,
    this.lastPowerUpdate,
  });
}

class CommunicationStatus {
  final CommState connection;
  final String? signalStrength;
  final DateTime? lastSuccessfulCommunication;
  final String? dataTransmission;
  final Duration? connectionDuration;
  const CommunicationStatus({
    required this.connection,
    this.signalStrength,
    this.lastSuccessfulCommunication,
    this.dataTransmission,
    this.connectionDuration,
  });
}

class GpsStatus {
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final String? fixStatus;
  final DateTime? lastGpsUpdate;
  final double? monitoringRadius;
  const GpsStatus({
    this.latitude,
    this.longitude,
    this.accuracy,
    this.fixStatus,
    this.lastGpsUpdate,
    this.monitoringRadius,
  });
}

class SuppressionStatus {
  final SuppressionState suppressionState;
  final RelayState relayState;
  final DateTime? lastActivation;
  final Duration? duration;
  final String? readiness;
  final String? lastDiagnostic;
  final String? fault;
  final String? cartridgeStatus;
  const SuppressionStatus({
    required this.suppressionState,
    required this.relayState,
    this.lastActivation,
    this.duration,
    this.readiness,
    this.lastDiagnostic,
    this.fault,
    this.cartridgeStatus,
  });
}

class AlertRecord {
  final String id;
  final Severity severity;
  final String title;
  final String component;
  final String capsuleId;
  final DateTime? detectionTime;
  final String status;
  const AlertRecord({
    required this.id,
    required this.severity,
    required this.title,
    required this.component,
    required this.capsuleId,
    this.detectionTime,
    required this.status,
  });
}

class MaintenanceStatus {
  final DateTime? installationDate;
  final DateTime? lastMaintenance;
  final DateTime? nextMaintenance;
  final DateTime? sensorCalibration;
  final String? hardwareCondition;
  final String? firmwareVersion;
  final DateTime? suppressionInspection;
  final String? maintenanceState;
  const MaintenanceStatus({
    this.installationDate,
    this.lastMaintenance,
    this.nextMaintenance,
    this.sensorCalibration,
    this.hardwareCondition,
    this.firmwareVersion,
    this.suppressionInspection,
    this.maintenanceState,
  });
}

class ActivityEvent {
  final DateTime timestamp;
  final String eventType;
  final String description;
  final String? component;
  final String? result;
  final String? userOrSystem;
  const ActivityEvent({
    required this.timestamp,
    required this.eventType,
    required this.description,
    this.component,
    this.result,
    this.userOrSystem,
  });
}

class TelemetryPoint {
  final DateTime timestamp;
  final double value;
  const TelemetryPoint({required this.timestamp, required this.value});
}

class SystemHealth {
  final int? capsulesOnline;
  final int? capsulesTotal;
  final int? sensorsOperational;
  final int? sensorsTotal;
  final int? commHealthy;
  final int? commDegraded;
  final int? commOffline;
  final String? powerSummary;
  const SystemHealth({
    this.capsulesOnline,
    this.capsulesTotal,
    this.sensorsOperational,
    this.sensorsTotal,
    this.commHealthy,
    this.commDegraded,
    this.commOffline,
    this.powerSummary,
  });
}

class SystemLog {
  final String id;
  final DateTime timestamp;
  final String capsuleId;
  final String component;
  final String event;
  final Severity severity;
  final String status;
  final String userOrSystem;
  const SystemLog({
    required this.id,
    required this.timestamp,
    required this.capsuleId,
    required this.component,
    required this.event,
    required this.severity,
    required this.status,
    required this.userOrSystem,
  });
}

class UserPermissions {
  final bool canDiagnose;
  final bool canTest;
  final bool canConfigure;
  final bool canUpdateFirmware;
  final bool canScheduleMaintenance;
  final bool canControlSuppression;
  const UserPermissions({
    required this.canDiagnose,
    required this.canTest,
    required this.canConfigure,
    required this.canUpdateFirmware,
    required this.canScheduleMaintenance,
    required this.canControlSuppression,
  });
}

class ActionResult {
  final bool success;
  final String message;
  const ActionResult({required this.success, required this.message});
}

// ============================================================
// BACKEND REPOSITORY - Implement these with real API + WS/MQTT
// ============================================================
abstract class FireGuardRepository {
  Future<CapsuleIdentity?> fetchCapsuleIdentity(String capsuleId);
  Future<List<SensorReading>> fetchLiveSensors(String capsuleId);
  Future<FireVerificationData?> fetchVerification(String capsuleId);
  Future<List<AutonomousResponseStage>> fetchResponseStages(String capsuleId);
  Future<List<DeviceComponentHealth>> fetchDeviceHealth(String capsuleId);
  Future<PowerStatus?> fetchPowerStatus(String capsuleId);
  Future<CommunicationStatus?> fetchCommunicationStatus(String capsuleId);
  Future<GpsStatus?> fetchGpsStatus(String capsuleId);
  Future<SuppressionStatus?> fetchSuppressionStatus(String capsuleId);
  Future<List<AlertRecord>> fetchRecentAlerts(String capsuleId);
  Future<MaintenanceStatus?> fetchMaintenanceStatus(String capsuleId);
  Future<List<ActivityEvent>> fetchActivityHistory(String capsuleId);
  Future<List<TelemetryPoint>> fetchTelemetry(
      String capsuleId, String sensorId, String timeRange);
  Future<SystemHealth?> fetchSystemHealth();
  Future<List<SystemLog>> fetchSystemLogs({String? query});
  Future<UserPermissions> fetchPermissions();

  // Actions - must return backend-confirmed result
  Future<ActionResult> runDiagnostics(String capsuleId);
  Future<ActionResult> testSensors(String capsuleId);
  Future<ActionResult> refreshData(String capsuleId);
  Future<ActionResult> configureCapsule(String capsuleId);
  Future<ActionResult> updateFirmware(String capsuleId);
  Future<ActionResult> scheduleMaintenance(String capsuleId);

  // Real-time streams - connect to WebSocket/MQTT
  Stream<SensorReading> get liveSensorStream;
  Stream<CommunicationStatus> get liveCommunicationStream;
  Stream<AlertRecord> get liveAlertStream;
}

// Empty implementation that returns no data - no fake values
class EmptyFireGuardRepository implements FireGuardRepository {
  final _sensorCtrl = StreamController<SensorReading>.broadcast();
  final _commCtrl = StreamController<CommunicationStatus>.broadcast();
  final _alertCtrl = StreamController<AlertRecord>.broadcast();

  @override
  Stream<SensorReading> get liveSensorStream => _sensorCtrl.stream;
  @override
  Stream<CommunicationStatus> get liveCommunicationStream => _commCtrl.stream;
  @override
  Stream<AlertRecord> get liveAlertStream => _alertCtrl.stream;

  @override
  Future<CapsuleIdentity?> fetchCapsuleIdentity(String capsuleId) async => null;
  @override
  Future<List<SensorReading>> fetchLiveSensors(String capsuleId) async => [];
  @override
  Future<FireVerificationData?> fetchVerification(String capsuleId) async =>
      null;
  @override
  Future<List<AutonomousResponseStage>> fetchResponseStages(
          String capsuleId) async =>
      [];
  @override
  Future<List<DeviceComponentHealth>> fetchDeviceHealth(
          String capsuleId) async =>
      [];
  @override
  Future<PowerStatus?> fetchPowerStatus(String capsuleId) async => null;
  @override
  Future<CommunicationStatus?> fetchCommunicationStatus(
          String capsuleId) async =>
      null;
  @override
  Future<GpsStatus?> fetchGpsStatus(String capsuleId) async => null;
  @override
  Future<SuppressionStatus?> fetchSuppressionStatus(String capsuleId) async =>
      null;
  @override
  Future<List<AlertRecord>> fetchRecentAlerts(String capsuleId) async => [];
  @override
  Future<MaintenanceStatus?> fetchMaintenanceStatus(String capsuleId) async =>
      null;
  @override
  Future<List<ActivityEvent>> fetchActivityHistory(String capsuleId) async =>
      [];
  @override
  Future<List<TelemetryPoint>> fetchTelemetry(
          String capsuleId, String sensorId, String timeRange) async =>
      [];
  @override
  Future<SystemHealth?> fetchSystemHealth() async => null;
  @override
  Future<List<SystemLog>> fetchSystemLogs({String? query}) async => [];
  @override
  Future<UserPermissions> fetchPermissions() async => const UserPermissions(
      canDiagnose: true,
      canTest: true,
      canConfigure: false,
      canUpdateFirmware: false,
      canScheduleMaintenance: true,
      canControlSuppression: false);
  @override
  Future<ActionResult> runDiagnostics(String capsuleId) async =>
      const ActionResult(success: false, message: 'Backend not connected');
  @override
  Future<ActionResult> testSensors(String capsuleId) async =>
      const ActionResult(success: false, message: 'Backend not connected');
  @override
  Future<ActionResult> refreshData(String capsuleId) async =>
      const ActionResult(success: false, message: 'Backend not connected');
  @override
  Future<ActionResult> configureCapsule(String capsuleId) async =>
      const ActionResult(success: false, message: 'Backend not connected');
  @override
  Future<ActionResult> updateFirmware(String capsuleId) async =>
      const ActionResult(success: false, message: 'Backend not connected');
  @override
  Future<ActionResult> scheduleMaintenance(String capsuleId) async =>
      const ActionResult(success: false, message: 'Backend not connected');
}

// ============================================================
// API REPOSITORY - Real backend implementation
// ============================================================
class ApiFireGuardRepository implements FireGuardRepository {
  final String baseUrl;
  ApiFireGuardRepository({this.baseUrl = 'https://api.fireguard.local'});

  // Live stream controllers
  final _sensorCtrl = StreamController<SensorReading>.broadcast();
  final _commCtrl = StreamController<CommunicationStatus>.broadcast();
  final _alertCtrl = StreamController<AlertRecord>.broadcast();

  @override
  Stream<SensorReading> get liveSensorStream => _sensorCtrl.stream;

  @override
  Stream<CommunicationStatus> get liveCommunicationStream => _commCtrl.stream;

  @override
  Stream<AlertRecord> get liveAlertStream => _alertCtrl.stream;

  Map<String, String> get _headers => {'Content-Type': 'application/json'};

  Future<dynamic> _getJson(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final res = await http
       .get(uri, headers: _headers)
       .timeout(const Duration(seconds: 10));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      return jsonDecode(res.body);
    }
    return null;
  }

  // ---- Helpers ----
  CapsuleOperationalState _parseOperational(String? v) {
    switch (v?.toLowerCase()) {
      case 'warning':
        return CapsuleOperationalState.warning;
      case 'critical':
        return CapsuleOperationalState.critical;
      case 'offline':
        return CapsuleOperationalState.offline;
      default:
        return CapsuleOperationalState.operational;
    }
  }

  SensorSystemState _parseSensorState(String? v) {
    switch (v?.toLowerCase()) {
      case 'elevated':
        return SensorSystemState.elevated;
      case 'critical':
        return SensorSystemState.critical;
      case 'nodata':
      case 'no_data':
      case 'no-data':
        return SensorSystemState.noData;
      case 'fault':
        return SensorSystemState.fault;
      default:
        return SensorSystemState.normal;
    }
  }

  IconData _iconForSensor(String id) {
    switch (id) {
      case 'flame_sensor':
        return Icons.local_fire_department;
      case 'mq2':
        return Icons.cloud;
      case 'mq7':
        return Icons.co2;
      case 'temperature':
        return Icons.thermostat;
      case 'humidity':
        return Icons.water_drop;
      case 'mlx90614':
        return Icons.thermostat_auto;
      default:
        return Icons.sensors;
    }
  }

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return null;
    }
  }

  // ---- Implementations ----
  @override
  Future<CapsuleIdentity?> fetchCapsuleIdentity(String capsuleId) async {
    try {
      final data = await _getJson('/capsules/$capsuleId');
      if (data == null) return null;
      return CapsuleIdentity(
        capsuleId: data['capsuleId']?? data['id']?? capsuleId,
        name: data['name']?? capsuleId,
        installationLocation:
            data['installationLocation']?? data['location']?? 'NO DATA',
        operationalState:
            _parseOperational(data['operationalState']?? data['state']),
        lastCommunication: _parseDate(data['lastCommunication']),
        lastSensorUpdate: _parseDate(data['lastSensorUpdate']),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<SensorReading>> fetchLiveSensors(String capsuleId) async {
    try {
      final data = await _getJson('/capsules/$capsuleId/sensors');
      if (data == null || data is! List) return [];
      return data.map<SensorReading>((e) {
        return SensorReading(
          sensorId: e['sensorId']?? e['id']?? 'unknown',
          sensorName: e['sensorName']?? e['name']?? e['sensorId']?? 'Sensor',
          icon: _iconForSensor(e['sensorId']?? ''),
          value: e['value']?.toString(),
          unit: e['unit']?.toString(),
          displayState: e['displayState']?.toString(),
          systemState: _parseSensorState(e['systemState']?? e['state']),
          timestamp: _parseDate(e['timestamp']),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<FireVerificationData?> fetchVerification(String capsuleId) async {
    try {
      final data = await _getJson('/capsules/$capsuleId/verification');
      if (data == null) return null;
      VerificationState vs;
      switch ((data['state'] as String?)?.toLowerCase()) {
        case 'suspected':
          vs = VerificationState.suspected;
          break;
        case 'verified':
          vs = VerificationState.verified;
          break;
        case 'failed':
          vs = VerificationState.failed;
          break;
        default:
          vs = VerificationState.monitoring;
      }
      final ev = <String, SensorSystemState>{};
      if (data['evidence'] is Map) {
        (data['evidence'] as Map).forEach(
            (k, v) => ev[k.toString()] = _parseSensorState(v.toString()));
      }
      return FireVerificationData(
        state: vs,
        verificationTime: _parseDate(data['verificationTime']),
        detectionSource: data['detectionSource']?.toString(),
        aiStatus: data['aiStatus']?.toString(),
        confidenceScore: (data['confidenceScore'] as num?)?.toDouble(),
        evidence: ev,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<AutonomousResponseStage>> fetchResponseStages(
      String capsuleId) async {
    try {
      final data = await _getJson('/capsules/$capsuleId/response-stages');
      if (data == null || data is! List) return [];
      return data.map<AutonomousResponseStage>((e) {
        ResponseStageState st;
        switch ((e['state'] as String?)?.toLowerCase()) {
          case 'active':
            st = ResponseStageState.active;
            break;
          case 'completed':
            st = ResponseStageState.completed;
            break;
          case 'failed':
            st = ResponseStageState.failed;
            break;
          default:
            st = ResponseStageState.pending;
        }
        return AutonomousResponseStage(
          id: e['id']?.toString()?? 'stage',
          name: e['name']?.toString()?? 'Stage',
          icon: Icons.shield,
          state: st,
          completedAt: _parseDate(e['completedAt']),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<DeviceComponentHealth>> fetchDeviceHealth(
      String capsuleId) async {
    try {
      final data = await _getJson('/capsules/$capsuleId/health');
      if (data == null || data is! List) return [];
      return data
         .map<DeviceComponentHealth>((e) => DeviceComponentHealth(
                componentName: e['componentName']?.toString()?? 'Component',
                status: _parseSensorState(e['status']?.toString()),
                lastDiagnostic: _parseDate(e['lastDiagnostic']),
                lastCommunication: _parseDate(e['lastCommunication']),
                diagnosticResult: e['diagnosticResult']?.toString(),
              ))
         .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<PowerStatus?> fetchPowerStatus(String capsuleId) async {
    try {
      final data = await _getJson('/capsules/$capsuleId/power');
      if (data == null) return null;
      PowerSource ps;
      switch ((data['powerSource'] as String?)?.toLowerCase()) {
        case 'battery':
          ps = PowerSource.battery;
          break;
        case 'solar':
          ps = PowerSource.solar;
          break;
        default:
          ps = PowerSource.unknown;
      }
      return PowerStatus(
        batteryPercent: (data['batteryPercent'] as num?)?.toDouble(),
        batteryHealth: data['batteryHealth']?.toString(),
        solarCharging: data['solarCharging'] as bool?,
        powerSource: ps,
        chargingState: data['chargingState']?.toString(),
        lastPowerUpdate: _parseDate(data['lastPowerUpdate']),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<CommunicationStatus?> fetchCommunicationStatus(
      String capsuleId) async {
    try {
      final data = await _getJson('/capsules/$capsuleId/communication');
      if (data == null) return null;
      CommState cs;
      switch ((data['connection'] as String?)?.toLowerCase()) {
        case 'degraded':
          cs = CommState.degraded;
          break;
        case 'offline':
          cs = CommState.offline;
          break;
        default:
          cs = CommState.online;
      }
      return CommunicationStatus(
        connection: cs,
        signalStrength: data['signalStrength']?.toString(),
        lastSuccessfulCommunication:
            _parseDate(data['lastSuccessfulCommunication']),
        dataTransmission: data['dataTransmission']?.toString(),
        connectionDuration: data['connectionDuration']!= null
           ? Duration(seconds: (data['connectionDuration'] as num).toInt())
            : null,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<GpsStatus?> fetchGpsStatus(String capsuleId) async {
    try {
      final data = await _getJson('/capsules/$capsuleId/gps');
      if (data == null) return null;
      return GpsStatus(
        latitude: (data['latitude'] as num?)?.toDouble(),
        longitude: (data['longitude'] as num?)?.toDouble(),
        accuracy: (data['accuracy'] as num?)?.toDouble(),
        fixStatus: data['fixStatus']?.toString(),
        lastGpsUpdate: _parseDate(data['lastGpsUpdate']),
        monitoringRadius: (data['monitoringRadius'] as num?)?.toDouble(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<SuppressionStatus?> fetchSuppressionStatus(String capsuleId) async {
    try {
      final data = await _getJson('/capsules/$capsuleId/suppression');
      if (data == null) return null;
      SuppressionState ss;
      switch ((data['suppressionState'] as String?)?.toLowerCase()) {
        case 'active':
          ss = SuppressionState.active;
          break;
        case 'completed':
          ss = SuppressionState.completed;
          break;
        case 'fault':
          ss = SuppressionState.fault;
          break;
        default:
          ss = SuppressionState.ready;
      }
      RelayState rs;
      switch ((data['relayState'] as String?)?.toLowerCase()) {
        case 'on':
          rs = RelayState.on;
          break;
        case 'off':
          rs = RelayState.off;
          break;
        default:
          rs = RelayState.unknown;
      }
      return SuppressionStatus(
        suppressionState: ss,
        relayState: rs,
        lastActivation: _parseDate(data['lastActivation']),
        duration: data['duration']!= null
           ? Duration(seconds: (data['duration'] as num).toInt())
            : null,
        readiness: data['readiness']?.toString(),
        lastDiagnostic: data['lastDiagnostic']?.toString(),
        fault: data['fault']?.toString(),
        cartridgeStatus: data['cartridgeStatus']?.toString(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<AlertRecord>> fetchRecentAlerts(String capsuleId) async {
    try {
      final data = await _getJson('/capsules/$capsuleId/alerts');
      if (data == null || data is! List) return [];
      return data.map<AlertRecord>((e) {
        Severity sev;
        switch ((e['severity'] as String?)?.toLowerCase()) {
          case 'warning':
            sev = Severity.warning;
            break;
          case 'error':
            sev = Severity.error;
            break;
          case 'critical':
            sev = Severity.critical;
            break;
          case 'success':
            sev = Severity.success;
            break;
          default:
            sev = Severity.info;
        }
        return AlertRecord(
          id: e['id']?.toString()?? '',
          severity: sev,
          title: e['title']?.toString()?? 'Alert',
          component: e['component']?.toString()?? 'System',
          capsuleId: e['capsuleId']?.toString()?? capsuleId,
          detectionTime: _parseDate(e['detectionTime']),
          status: e['status']?.toString()?? 'active',
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<MaintenanceStatus?> fetchMaintenanceStatus(String capsuleId) async {
    try {
      final data = await _getJson('/capsules/$capsuleId/maintenance');
      if (data == null) return null;
      return MaintenanceStatus(
        installationDate: _parseDate(data['installationDate']),
        lastMaintenance: _parseDate(data['lastMaintenance']),
        nextMaintenance: _parseDate(data['nextMaintenance']),
        sensorCalibration: _parseDate(data['sensorCalibration']),
        hardwareCondition: data['hardwareCondition']?.toString(),
        firmwareVersion: data['firmwareVersion']?.toString(),
        suppressionInspection: _parseDate(data['suppressionInspection']),
        maintenanceState: data['maintenanceState']?.toString(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<ActivityEvent>> fetchActivityHistory(String capsuleId) async {
    try {
      final data = await _getJson('/capsules/$capsuleId/activity');
      if (data == null || data is! List) return [];
      return data
         .map<ActivityEvent>((e) => ActivityEvent(
                timestamp: _parseDate(e['timestamp'])?? DateTime.now(),
                eventType: e['eventType']?.toString()?? 'event',
                description: e['description']?.toString()?? '',
                component: e['component']?.toString(),
                result: e['result']?.toString(),
                userOrSystem: e['userOrSystem']?.toString(),
              ))
         .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<TelemetryPoint>> fetchTelemetry(
      String capsuleId, String sensorId, String timeRange) async {
    try {
      final data = await _getJson(
          '/capsules/$capsuleId/telemetry?sensor=$sensorId&range=${Uri.encodeComponent(timeRange)}');
      if (data == null || data is! List) return [];
      return data
         .map<TelemetryPoint>((e) => TelemetryPoint(
                timestamp: _parseDate(e['timestamp'])?? DateTime.now(),
                value: (e['value'] as num).toDouble(),
              ))
         .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<SystemHealth?> fetchSystemHealth() async {
    try {
      final data = await _getJson('/system/health');
      if (data == null) return null;
      return SystemHealth(
        capsulesOnline: data['capsulesOnline'] as int?,
        capsulesTotal: data['capsulesTotal'] as int?,
        sensorsOperational: data['sensorsOperational'] as int?,
        sensorsTotal: data['sensorsTotal'] as int?,
        commHealthy: data['commHealthy'] as int?,
        commDegraded: data['commDegraded'] as int?,
        commOffline: data['commOffline'] as int?,
        powerSummary: data['powerSummary']?.toString(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<SystemLog>> fetchSystemLogs({String? query}) async {
    try {
      final path = query!= null
         ? '/system/logs?q=${Uri.encodeComponent(query)}'
          : '/system/logs';
      final data = await _getJson(path);
      if (data == null || data is! List) return [];
      return data.map<SystemLog>((e) {
        Severity sev;
        switch ((e['severity'] as String?)?.toLowerCase()) {
          case 'warning':
            sev = Severity.warning;
            break;
          case 'error':
            sev = Severity.error;
            break;
          case 'critical':
            sev = Severity.critical;
            break;
          case 'success':
            sev = Severity.success;
            break;
          default:
            sev = Severity.info;
        }
        return SystemLog(
          id: e['id']?.toString()?? '',
          timestamp: _parseDate(e['timestamp'])?? DateTime.now(),
          capsuleId: e['capsuleId']?.toString()?? '',
          component: e['component']?.toString()?? '',
          event: e['event']?.toString()?? '',
          severity: sev,
          status: e['status']?.toString()?? '',
          userOrSystem: e['userOrSystem']?.toString()?? 'System',
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<UserPermissions> fetchPermissions() async {
    try {
      final data = await _getJson('/permissions');
      if (data == null) {
        return const UserPermissions(
            canDiagnose: true,
            canTest: true,
            canConfigure: false,
            canUpdateFirmware: false,
            canScheduleMaintenance: true,
            canControlSuppression: false);
      }
      return UserPermissions(
  canDiagnose: data['canDiagnose'] as bool? ?? false,
  canTest: data['canTest'] as bool? ?? false,
  canConfigure: data['canConfigure'] as bool? ?? false,
  canUpdateFirmware: data['canUpdateFirmware'] as bool? ?? false,
  canScheduleMaintenance:
      data['canScheduleMaintenance'] as bool? ?? false,
  canControlSuppression:
      data['canControlSuppression'] as bool? ?? false,
);
    } catch (_) {
      return const UserPermissions(
          canDiagnose: true,
          canTest: true,
          canConfigure: false,
          canUpdateFirmware: false,
          canScheduleMaintenance: true,
          canControlSuppression: false);
    }
  }

  @override
  Future<ActionResult> runDiagnostics(String capsuleId) async {
    return const ActionResult(
      success: false,
      message: 'Backend action not implemented yet',
    );
  }

  @override
  Future<ActionResult> testSensors(String capsuleId) async {
    return const ActionResult(
      success: false,
      message: 'Backend action not implemented yet',
    );
  }

  @override
  Future<ActionResult> refreshData(String capsuleId) async {
    return const ActionResult(
      success: false,
      message: 'Backend action not implemented yet',
    );
  }

  @override
  Future<ActionResult> configureCapsule(String capsuleId) async {
    return const ActionResult(
      success: false,
      message: 'Backend action not implemented yet',
    );
  }

  @override
  Future<ActionResult> updateFirmware(String capsuleId) async {
    return const ActionResult(
      success: false,
      message: 'Backend action not implemented yet',
    );
  }

  @override
  Future<ActionResult> scheduleMaintenance(String capsuleId) async {
    return const ActionResult(
      success: false,
      message: 'Backend action not implemented yet',
    );
  }
}

// ============================================================
// MAIN SCREEN
// ============================================================
class FireGuardCapsuleDetailScreen extends StatefulWidget {
  final String capsuleId;
  final FireGuardRepository? repository;
  const FireGuardCapsuleDetailScreen(
      {super.key, required this.capsuleId, this.repository});

  @override
  State<FireGuardCapsuleDetailScreen> createState() =>
      _FireGuardCapsuleDetailScreenState();
}

class _FireGuardCapsuleDetailScreenState
    extends State<FireGuardCapsuleDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late FireGuardRepository _repo;

  // Independent loading states
  bool identityLoading = true;
  bool sensorsLoading = true;
  bool verificationLoading = true;
  bool responseLoading = true;
  bool healthLoading = true;
  bool powerLoading = true;
  bool commLoading = true;
  bool gpsLoading = true;
  bool suppressionLoading = true;
  bool alertsLoading = true;
  bool maintenanceLoading = true;
  bool activityLoading = true;
  bool telemetryLoading = false;
  bool systemHealthLoading = true;
  bool logsLoading = true;

  // Data
  CapsuleIdentity? identity;
  List<SensorReading> sensors = [];
  FireVerificationData? verification;
  List<AutonomousResponseStage> responseStages = [];
  List<DeviceComponentHealth> deviceHealth = [];
  PowerStatus? powerStatus;
  CommunicationStatus? commStatus;
  GpsStatus? gpsStatus;
  SuppressionStatus? suppressionStatus;
  List<AlertRecord> alerts = [];
  MaintenanceStatus? maintenanceStatus;
  List<ActivityEvent> activityEvents = [];
  List<TelemetryPoint> telemetryPoints = [];
  SystemHealth? systemHealth;
  List<SystemLog> systemLogs = [];
  UserPermissions? permissions;

  // Errors per section
  String? identityError;
  String? sensorsError;
  String? verificationError;

  // Telemetry selection
  String selectedSensorId = 'temperature';
  String selectedTimeRange = '24 Hours';

  // Live subscriptions
  StreamSubscription<SensorReading>? _sensorSub;
  StreamSubscription<CommunicationStatus>? _commSub;
  StreamSubscription<AlertRecord>? _alertSub;
  Timer? _ageTimer;

  bool _actionInProgress = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _repo = widget.repository?? ApiFireGuardRepository();
    _startSequentialLoad();
    _subscribeLive();
    _ageTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _startSequentialLoad() async {
    await _loadIdentity();
    await Future.wait([_loadSensors(), _loadVerification(), _loadResponse()]);
    await Future.wait([
      _loadDeviceHealth(),
      _loadPower(),
      _loadComm(),
      _loadGps(),
      _loadSuppression()
    ]);
    await Future.wait([
      _loadAlerts(),
      _loadMaintenance(),
      _loadActivity(),
      _loadSystemHealth(),
      _loadLogs()
    ]);
    await _loadTelemetry();
    final perms = await _repo.fetchPermissions();
    if (mounted) setState(() => permissions = perms);
  }

  Future<void> _loadIdentity() async {
    setState(() {
      identityLoading = true;
      identityError = null;
    });
    try {
      final data = await _repo.fetchCapsuleIdentity(widget.capsuleId);
      if (mounted)
        setState(() {
          identity = data;
          identityLoading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          identityError = e.toString();
          identityLoading = false;
        });
    }
  }

  Future<void> _loadSensors() async {
    setState(() {
      sensorsLoading = true;
      sensorsError = null;
    });
    try {
      final data = await _repo.fetchLiveSensors(widget.capsuleId);
      if (mounted)
        setState(() {
          sensors = data;
          sensorsLoading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          sensorsError = e.toString();
          sensorsLoading = false;
        });
    }
  }

  Future<void> _loadVerification() async {
    setState(() => verificationLoading = true);
    try {
      final data = await _repo.fetchVerification(widget.capsuleId);
      if (mounted)
        setState(() {
          verification = data;
          verificationLoading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          verificationError = e.toString();
          verificationLoading = false;
        });
    }
  }

  Future<void> _loadResponse() async {
    setState(() => responseLoading = true);
    try {
      final data = await _repo.fetchResponseStages(widget.capsuleId);
      if (mounted)
        setState(() {
          responseStages = data;
          responseLoading = false;
        });
    } catch (_) {
      if (mounted) setState(() => responseLoading = false);
    }
  }

  Future<void> _loadDeviceHealth() async {
    setState(() => healthLoading = true);
    try {
      final data = await _repo.fetchDeviceHealth(widget.capsuleId);
      if (mounted)
        setState(() {
          deviceHealth = data;
          healthLoading = false;
        });
    } catch (_) {
      if (mounted) setState(() => healthLoading = false);
    }
  }

  Future<void> _loadPower() async {
    setState(() => powerLoading = true);
    try {
      final data = await _repo.fetchPowerStatus(widget.capsuleId);
      if (mounted)
        setState(() {
          powerStatus = data;
          powerLoading = false;
        });
    } catch (_) {
      if (mounted) setState(() => powerLoading = false);
    }
  }

  Future<void> _loadComm() async {
    setState(() => commLoading = true);
    try {
      final data = await _repo.fetchCommunicationStatus(widget.capsuleId);
      if (mounted)
        setState(() {
          commStatus = data;
          commLoading = false;
        });
    } catch (_) {
      if (mounted) setState(() => commLoading = false);
    }
  }

  Future<void> _loadGps() async {
    setState(() => gpsLoading = true);
    try {
      final data = await _repo.fetchGpsStatus(widget.capsuleId);
      if (mounted)
        setState(() {
          gpsStatus = data;
          gpsLoading = false;
        });
    } catch (_) {
      if (mounted) setState(() => gpsLoading = false);
    }
  }

  Future<void> _loadSuppression() async {
    setState(() => suppressionLoading = true);
    try {
      final data = await _repo.fetchSuppressionStatus(widget.capsuleId);
      if (mounted)
        setState(() {
          suppressionStatus = data;
          suppressionLoading = false;
        });
    } catch (_) {
      if (mounted) setState(() => suppressionLoading = false);
    }
  }

  Future<void> _loadAlerts() async {
    setState(() => alertsLoading = true);
    try {
      final data = await _repo.fetchRecentAlerts(widget.capsuleId);
      if (mounted)
        setState(() {
          alerts = data;
          alertsLoading = false;
        });
    } catch (_) {
      if (mounted) setState(() => alertsLoading = false);
    }
  }

  Future<void> _loadMaintenance() async {
    setState(() => maintenanceLoading = true);
    try {
      final data = await _repo.fetchMaintenanceStatus(widget.capsuleId);
      if (mounted)
        setState(() {
          maintenanceStatus = data;
          maintenanceLoading = false;
        });
    } catch (_) {
      if (mounted) setState(() => maintenanceLoading = false);
    }
  }

  Future<void> _loadActivity() async {
    setState(() => activityLoading = true);
    try {
      final data = await _repo.fetchActivityHistory(widget.capsuleId);
      if (mounted)
        setState(() {
          activityEvents = data;
          activityLoading = false;
        });
    } catch (_) {
      if (mounted) setState(() => activityLoading = false);
    }
  }

  Future<void> _loadTelemetry() async {
    setState(() => telemetryLoading = true);
    try {
      final data = await _repo.fetchTelemetry(
          widget.capsuleId, selectedSensorId, selectedTimeRange);
      if (mounted)
        setState(() {
          telemetryPoints = data;
          telemetryLoading = false;
        });
    } catch (_) {
      if (mounted) setState(() => telemetryLoading = false);
    }
  }

  Future<void> _loadSystemHealth() async {
    setState(() => systemHealthLoading = true);
    try {
      final data = await _repo.fetchSystemHealth();
      if (mounted)
        setState(() {
          systemHealth = data;
          systemHealthLoading = false;
        });
    } catch (_) {
      if (mounted) setState(() => systemHealthLoading = false);
    }
  }

  Future<void> _loadLogs() async {
    setState(() => logsLoading = true);
    try {
      final data = await _repo.fetchSystemLogs();
      if (mounted)
        setState(() {
          systemLogs = data;
          logsLoading = false;
        });
    } catch (_) {
      if (mounted) setState(() => logsLoading = false);
    }
  }

  void _subscribeLive() {
    _sensorSub = _repo.liveSensorStream.listen((reading) {
      if (!mounted) return;
      setState(() {
        final idx = sensors.indexWhere((s) => s.sensorId == reading.sensorId);
        if (idx >= 0) {
          sensors[idx] = reading;
        } else {
          sensors = [...sensors, reading];
        }
      });
    });
    _commSub = _repo.liveCommunicationStream.listen((comm) {
      if (!mounted) return;
      setState(() => commStatus = comm);
    });
    _alertSub = _repo.liveAlertStream.listen((alert) {
      if (!mounted) return;
      setState(() => alerts = [alert,...alerts]);
    });
  }

  @override
  void dispose() {
    _sensorSub?.cancel();
    _commSub?.cancel();
    _alertSub?.cancel();
    _ageTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    return Scaffold(
      backgroundColor: FGColors.background,
      body: Row(
        children: [
          if (!isMobile) _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildHeader(isMobile),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCapsuleDetailScroll(isMobile),
                      _buildSystemHealthScroll(isMobile),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isMobile? _buildBottomNav() : null,
    );
  }

  // UI HELPERS
  Widget _buildSidebar() {
    return Container(
      width: 240,
      color: FGColors.panel,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            _sidebarItem(Icons.dashboard, 'Dashboard'),
            _sidebarItem(Icons.sensors, 'Capsules', selected: true),
            _sidebarItem(Icons.map, 'Map'),
            _sidebarItem(Icons.notifications, 'Alerts'),
            _sidebarItem(Icons.assessment, 'System Health'),
            const Spacer(),
            Container(height: 1, color: FGColors.border),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Backend → Repository → UI',
                  style:
                      TextStyle(color: FGColors.secondaryText, fontSize: 10)),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _sidebarItem(IconData icon, String label, {bool selected = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: selected? FGColors.elevated : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: selected? FGColors.border : Colors.transparent),
      ),
      child: ListTile(
        leading: Icon(icon,
            color: selected? FGColors.primaryText : FGColors.secondaryText,
            size: 20),
        title: Text(label,
            style: TextStyle(
                color: selected? FGColors.primaryText : FGColors.secondaryText,
                fontSize: 13)),
        onTap: () {
          // ADDED FOR NAVIGATION ONLY - Go back to Dashboard when Dashboard item tapped
          if (label == 'Dashboard') {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const FireGuardDashboard()),
              );
            }
          }
        },
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      height: isMobile? 56 : 72,
      padding: EdgeInsets.symmetric(horizontal: isMobile? 16 : 24),
      decoration: const BoxDecoration(
        color: FGColors.panel,
        border: Border(bottom: BorderSide(color: FGColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: FGColors.elevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: FGColors.border)),
            child: IconButton(
                icon: const Icon(Icons.arrow_back,
                    color: FGColors.primaryText, size: 20),
                // MODIFIED FOR NAVIGATION ONLY - Was empty, now goes back to Dashboard
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const FireGuardDashboard()),
                    );
                  }
                }),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Capsule Details',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: FGColors.primaryText)),
              if (!isMobile)
                const Text('Monitoring individual FireGuard capsule',
                    style:
                        TextStyle(fontSize: 12, color: FGColors.secondaryText)),
            ],
          ),
          const Spacer(),
          _headerIcon(Icons.refresh, onTap: _startSequentialLoad),
          const SizedBox(width: 8),
          _headerIcon(Icons.more_vert, onTap: () => _showMoreMenu()),
          const SizedBox(width: 8),
          _headerIcon(Icons.person),
        ],
      ),
    );
  }

  Widget _headerIcon(IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
            color: FGColors.elevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: FGColors.border)),
        child: Icon(icon, color: FGColors.primaryText, size: 20),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: FGColors.panel,
      child: TabBar(
        controller: _tabController,
        indicatorColor: FGColors.info,
        labelColor: FGColors.primaryText,
        unselectedLabelColor: FGColors.secondaryText,
        tabs: const [
          Tab(text: 'CAPSULE DETAIL'),
          Tab(text: 'SYSTEM HEALTH & LOGS')
        ],
      ),
    );
  }

  Widget _buildCapsuleDetailScroll(bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (identityLoading)
            _skeleton(height: 120)
          else if (identityError!= null)
            _errorState('Unable to load capsule data', onRetry: _loadIdentity)
          else if (identity!= null)
            _capsuleIdentityCard(identity!, isMobile)
          else
            _emptyState('Capsule identity unavailable - backend not connected'),
          SizedBox(height: isMobile? 16 : 20),
          _sectionTitle('Live Fire Detection'),
          const SizedBox(height: 12),
          if (sensorsLoading)
            _skeleton(height: 260)
          else if (sensorsError!= null)
            _errorState(sensorsError!, onRetry: _loadSensors)
          else
            _liveFireGrid(isMobile),
          SizedBox(height: isMobile? 16 : 20),
          if (verificationLoading)
            _skeleton(height: 200)
          else
            _fireVerificationPanel(),
          SizedBox(height: isMobile? 16 : 20),
          if (responseLoading)
            _skeleton(height: 180)
          else
            _autonomousResponsePanel(isMobile),
          SizedBox(height: isMobile? 16 : 20),
          isMobile
             ? Column(children: [
                  _deviceHealthPanel(),
                  const SizedBox(height: 16),
                  _powerPanel(),
                  const SizedBox(height: 16),
                  _communicationPanel()
                ])
              : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 60, child: _deviceHealthPanel()),
                  const SizedBox(width: 16),
                  Expanded(
                      flex: 40,
                      child: Column(children: [
                        _powerPanel(),
                        const SizedBox(height: 16),
                        _communicationPanel()
                      ])),
                ]),
          SizedBox(height: isMobile? 16 : 20),
          if (suppressionLoading)
            _skeleton(height: 200)
          else
            _suppressionPanel(),
          SizedBox(height: isMobile? 16 : 20),
          if (gpsLoading) _skeleton(height: 280) else _gpsLocationPanel(),
          SizedBox(height: isMobile? 16 : 20),
          _telemetryPanel(),
          SizedBox(height: isMobile? 16 : 20),
          if (alertsLoading) _skeleton(height: 240) else _recentAlertsPanel(),
          SizedBox(height: isMobile? 16 : 20),
          if (maintenanceLoading)
            _skeleton(height: 160)
          else
            _maintenancePanel(),
          SizedBox(height: isMobile? 16 : 20),
          if (activityLoading)
            _skeleton(height: 240)
          else
            _activityHistoryPanel(),
          SizedBox(height: isMobile? 16 : 20),
          _capsuleActionsPanel(isMobile),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // IDENTITY
  Widget _capsuleIdentityCard(CapsuleIdentity data, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: FGColors.panel,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: FGColors.border)),
      child: isMobile
         ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _identityLeft(data),
              const SizedBox(height: 12),
              _identityCenter(data),
              const SizedBox(height: 12),
              _identityRight(data),
              const SizedBox(height: 12),
              _identityActions(),
            ])
          : Row(children: [
              _identityLeft(data),
              const SizedBox(width: 32),
              _identityCenter(data),
              const Spacer(),
              _identityRight(data),
              const SizedBox(width: 24),
              _identityActions(),
            ]),
    );
  }

  Widget _identityLeft(CapsuleIdentity d) {
    return Row(children: [
      Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: FGColors.elevated, borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.memory, color: FGColors.info)),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(d.name,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: FGColors.primaryText)),
        Text(d.capsuleId,
            style:
                const TextStyle(fontSize: 12, color: FGColors.secondaryText)),
      ]),
    ]);
  }

  Widget _identityCenter(CapsuleIdentity d) {
    Color dot;
    String label;
    switch (d.operationalState) {
      case CapsuleOperationalState.operational:
        dot = FGColors.healthy;
        label = 'OPERATIONAL';
        break;
      case CapsuleOperationalState.warning:
        dot = FGColors.warning;
        label = 'WARNING';
        break;
      case CapsuleOperationalState.critical:
        dot = FGColors.critical;
        label = 'CRITICAL';
        break;
      case CapsuleOperationalState.offline:
        dot = FGColors.secondaryText;
        label = 'OFFLINE';
        break;
    }
    return Row(children: [
      Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Text(label,
          style:
              TextStyle(color: dot, fontWeight: FontWeight.w600, fontSize: 13)),
    ]);
  }

  Widget _identityRight(CapsuleIdentity d) {
    return Wrap(spacing: 24, children: [
      _metaItem('Installation location', d.installationLocation),
      _metaItem(
          'Last communication',
          d.lastCommunication!= null
             ? _formatTimeAgo(d.lastCommunication!)
              : 'NO DATA'),
      _metaItem(
          'Last sensor update',
          d.lastSensorUpdate!= null
             ? _formatTimeAgo(d.lastSensorUpdate!)
              : 'NO DATA'),
    ]);
  }

  Widget _metaItem(String label, String value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(fontSize: 11, color: FGColors.secondaryText)),
      const SizedBox(height: 2),
      Text(value,
          style: const TextStyle(fontSize: 12, color: FGColors.primaryText)),
    ]);
  }

  Widget _identityActions() {
    final canDiagnose = permissions?.canDiagnose?? false;
    return Row(children: [
      _actionButton('Open on Map', Icons.map, primary: false, enabled: true),
      const SizedBox(width: 8),
      _actionButton('Run Diagnostics', Icons.health_and_safety,
          primary: true, enabled: canDiagnose),
      const SizedBox(width: 8),
      Container(
        height: 44,
        width: 44,
        decoration: BoxDecoration(
            color: FGColors.elevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: FGColors.border)),
        child: const Icon(Icons.more_horiz, color: FGColors.primaryText),
      ),
    ]);
  }

  // SENSORS GRID
  Widget _liveFireGrid(bool isMobile) {
    if (sensors.isEmpty)
      return _emptyState(
          'No live sensor data - connect backend liveSensorStream');
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile? 2 : 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: isMobile? 1.1 : 1.7,
      ),
      itemCount: sensors.length,
      itemBuilder: (_, i) => _sensorCard(sensors[i]),
    );
  }

  Widget _sensorCard(SensorReading r) {
    Color statusColor;
    String statusText;
    switch (r.systemState) {
      case SensorSystemState.normal:
        statusColor = FGColors.healthy;
        statusText = 'Normal';
        break;
      case SensorSystemState.elevated:
        statusColor = FGColors.warning;
        statusText = 'Elevated';
        break;
      case SensorSystemState.critical:
        statusColor = FGColors.critical;
        statusText = 'Critical';
        break;
      case SensorSystemState.noData:
        statusColor = FGColors.secondaryText;
        statusText = 'No Data';
        break;
      case SensorSystemState.fault:
        statusColor = FGColors.critical;
        statusText = 'Fault';
        break;
    }
    final ageText =
        r.timestamp!= null? _formatTimeAgo(r.timestamp!) : 'NO DATA';
    final isStale = r.timestamp!= null &&
        DateTime.now().difference(r.timestamp!).inMinutes > 5;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: FGColors.panel,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: FGColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(r.icon, size: 16, color: FGColors.secondaryText),
            const SizedBox(width: 6),
            Expanded(
                child: Text(r.sensorName,
                    style: const TextStyle(
                        fontSize: 11, color: FGColors.secondaryText),
                    overflow: TextOverflow.ellipsis)),
            Container(
                width: 6,
                height: 6,
                decoration:
                    BoxDecoration(color: statusColor, shape: BoxShape.circle)),
          ]),
          const SizedBox(height: 8),
          Text(
              r.displayState??
                  (r.value!= null? '${r.value} ${r.unit?? ''}' : 'NO DATA'),
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: FGColors.primaryText)),
          const SizedBox(height: 4),
          Row(children: [
            Text(statusText,
                style: TextStyle(fontSize: 11, color: statusColor)),
            const Spacer(),
            Flexible(
                child: Text(isStale? 'DATA STALE' : ageText,
                    style: TextStyle(
                        fontSize: 10,
                        color: isStale
                           ? FGColors.warning
                            : FGColors.secondaryText))),
          ]),
          if (isStale)
            const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('DATA DELAYED',
                    style: TextStyle(
                        fontSize: 9,
                        color: FGColors.warning,
                        fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _fireVerificationPanel() {
    final state = verification?.state?? VerificationState.monitoring;
    String label;
    Color color;
    switch (state) {
      case VerificationState.monitoring:
        label = 'MONITORING';
        color = FGColors.healthy;
        break;
      case VerificationState.suspected:
        label = 'FIRE SUSPECTED';
        color = FGColors.warning;
        break;
      case VerificationState.verified:
        label = 'FIRE VERIFIED';
        color = FGColors.critical;
        break;
      case VerificationState.failed:
        label = 'VERIFICATION FAILED';
        color = FGColors.secondaryText;
        break;
    }
    if (verification == null)
      return _genericPanel('Fire Verification',
          height: 200,
          child: const Text('No verification data from backend',
              style: TextStyle(color: FGColors.secondaryText, fontSize: 11)));
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: FGColors.panel,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: FGColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Fire Verification',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: FGColors.primaryText)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: FGColors.elevated,
                              borderRadius: BorderRadius.circular(4)),
                          child: Text(label,
                              style: TextStyle(
                                  color: color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600))),
                      const SizedBox(height: 8),
                      Text(
                          'Verification time: ${verification!.verificationTime!= null? verification!.verificationTime.toString() : 'NO DATA'}',
                          style: const TextStyle(
                              color: FGColors.secondaryText, fontSize: 11)),
                      Text(
                          'Detection source: ${verification!.detectionSource?? 'NO DATA'}',
                          style: const TextStyle(
                              color: FGColors.secondaryText, fontSize: 11)),
                      Text('AI status: ${verification!.aiStatus?? 'NO DATA'}',
                          style: const TextStyle(
                              color: FGColors.secondaryText, fontSize: 11)),
                      if (verification!.confidenceScore!= null)
                        Text(
                            'Confidence: ${verification!.confidenceScore!.toStringAsFixed(2)}',
                            style: const TextStyle(
                                color: FGColors.info, fontSize: 11)),
                    ]),
              ),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: verification!.evidence.entries.map((e) {
                    Color dot;
                    switch (e.value) {
                      case SensorSystemState.normal:
                        dot = FGColors.healthy;
                        break;
                      case SensorSystemState.elevated:
                        dot = FGColors.warning;
                        break;
                      case SensorSystemState.critical:
                        dot = FGColors.critical;
                        break;
                      default:
                        dot = FGColors.secondaryText;
                    }
                    return Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                              color: dot, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text(e.key,
                          style: const TextStyle(
                              color: FGColors.secondaryText, fontSize: 11)),
                    ]);
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _autonomousResponsePanel(bool isMobile) {
    if (responseStages.isEmpty)
      return _genericPanel('Autonomous Response',
          height: 180,
          child: const Text('No response stages from backend',
              style: TextStyle(color: FGColors.secondaryText, fontSize: 11)));
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: FGColors.panel,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: FGColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Autonomous Response',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: FGColors.primaryText)),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: responseStages.map((stage) {
                Color c;
                switch (stage.state) {
                  case ResponseStageState.pending:
                    c = FGColors.secondaryText;
                    break;
                  case ResponseStageState.active:
                    c = FGColors.info;
                    break;
                  case ResponseStageState.completed:
                    c = FGColors.healthy;
                    break;
                  case ResponseStageState.failed:
                    c = FGColors.critical;
                    break;
                }
                final isActive = stage.state == ResponseStageState.active;
                return Row(children: [
                  Column(children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isActive
                           ? FGColors.info.withOpacity(0.15)
                            : FGColors.elevated,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: isActive? FGColors.info : FGColors.border,
                            width: isActive? 2 : 1),
                      ),
                      child: Icon(stage.icon, size: 16, color: c),
                    ),
                    const SizedBox(height: 6),
                    Text(stage.name,
                        style: TextStyle(
                            fontSize: 10,
                            color: c,
                            fontWeight:
                                isActive? FontWeight.w700 : FontWeight.w400)),
                    const SizedBox(height: 2),
                    Text(stage.state.name.toUpperCase(),
                        style: TextStyle(fontSize: 9, color: c)),
                    if (stage.completedAt!= null)
                      Text(_formatTimeAgo(stage.completedAt!),
                          style: const TextStyle(
                              fontSize: 9, color: FGColors.secondaryText)),
                  ]),
                  if (stage.id!= responseStages.last.id)
                    Container(
                        width: 40,
                        height: 1,
                        color: FGColors.border,
                        margin: const EdgeInsets.symmetric(horizontal: 8)),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _deviceHealthPanel() {
    if (healthLoading) return _skeleton(height: 240);
    if (deviceHealth.isEmpty)
      return _genericPanel('Device Health',
          height: 240,
          child: const Text(
              'No device health data - connect fetchDeviceHealth()',
              style: TextStyle(color: FGColors.secondaryText, fontSize: 11)));
    return _genericPanel(
      'Device Health',
      height: 260,
      child: Column(
        children: deviceHealth.map((h) {
          IconData icon;
          Color color;
          switch (h.status) {
            case SensorSystemState.normal:
              icon = Icons.check_circle;
              color = FGColors.healthy;
              break;
            case SensorSystemState.elevated:
              icon = Icons.warning;
              color = FGColors.warning;
              break;
            case SensorSystemState.critical:
            case SensorSystemState.fault:
              icon = Icons.error;
              color = FGColors.critical;
              break;
            default:
              icon = Icons.help;
              color = FGColors.secondaryText;
          }
          return ListTile(
            dense: true,
            leading: Icon(icon, color: color, size: 16),
            title: Text(h.componentName,
                style:
                    const TextStyle(color: FGColors.primaryText, fontSize: 11)),
            subtitle: Text(
                '${h.status.name} • Last diagnostic: ${h.lastDiagnostic!= null? _formatTimeAgo(h.lastDiagnostic!) : 'NO DATA'}',
                style: const TextStyle(
                    color: FGColors.secondaryText, fontSize: 10)),
          );
        }).toList(),
      ),
    );
  }

  Widget _powerPanel() {
    if (powerLoading) return _skeleton(height: 240);
    if (powerStatus == null)
      return _genericPanel('Power System',
          height: 240,
          child: const Text('No power data - connect fetchPowerStatus()',
              style: TextStyle(color: FGColors.secondaryText, fontSize: 11)));
    final pct = powerStatus!.batteryPercent;
    return _genericPanel(
      'Power System',
      height: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              pct!= null
                 ? 'Battery ${pct.toStringAsFixed(0)}%'
                  : 'Battery NO DATA',
              style: const TextStyle(
                  color: FGColors.primaryText,
                  fontSize: 24,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            height: 8,
            decoration: BoxDecoration(
                color: const Color(0xFF1B3045),
                borderRadius: BorderRadius.circular(4)),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: pct!= null? (pct / 100).clamp(0, 1) : 0,
              child: Container(
                  decoration: BoxDecoration(
                      color: FGColors.healthy,
                      borderRadius: BorderRadius.circular(4))),
            ),
          ),
          const SizedBox(height: 12),
          Text('Battery Health: ${powerStatus!.batteryHealth?? 'NO DATA'}',
              style:
                  const TextStyle(color: FGColors.secondaryText, fontSize: 11)),
          Text(
              'Solar Charging: ${powerStatus!.solarCharging == true? 'Charging' : powerStatus!.solarCharging == false? 'Not Charging' : 'NO DATA'}',
              style:
                  const TextStyle(color: FGColors.secondaryText, fontSize: 11)),
          Text('Power Source: ${powerStatus!.powerSource.name}',
              style:
                  const TextStyle(color: FGColors.secondaryText, fontSize: 11)),
          Text('Charging State: ${powerStatus!.chargingState?? 'NO DATA'}',
              style:
                  const TextStyle(color: FGColors.secondaryText, fontSize: 11)),
          Text(
              'Last Power Update: ${powerStatus!.lastPowerUpdate!= null? _formatTimeAgo(powerStatus!.lastPowerUpdate!) : 'NO DATA'}',
              style:
                  const TextStyle(color: FGColors.secondaryText, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _communicationPanel() {
    if (commLoading) return _skeleton(height: 180);
    if (commStatus == null)
      return _genericPanel('Communication',
          height: 180,
          child: const Text(
              'No communication data - connect fetchCommunicationStatus()',
              style: TextStyle(color: FGColors.secondaryText, fontSize: 11)));
    Color connColor;
    switch (commStatus!.connection) {
      case CommState.online:
        connColor = FGColors.healthy;
        break;
      case CommState.degraded:
        connColor = FGColors.warning;
        break;
      case CommState.offline:
        connColor = FGColors.critical;
        break;
    }
    return _genericPanel(
      'Communication',
      height: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('GSM 900',
              style: TextStyle(
                  color: FGColors.primaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Connection: ${commStatus!.connection.name.toUpperCase()}',
              style: TextStyle(
                  color: connColor, fontSize: 11, fontWeight: FontWeight.w600)),
          Text('Signal Strength: ${commStatus!.signalStrength?? 'NO DATA'}',
              style:
                  const TextStyle(color: FGColors.secondaryText, fontSize: 11)),
          Text(
              'Last Successful Communication: ${commStatus!.lastSuccessfulCommunication!= null? _formatTimeAgo(commStatus!.lastSuccessfulCommunication!) : 'NO DATA'}',
              style:
                  const TextStyle(color: FGColors.secondaryText, fontSize: 11)),
          Text(
              'Data Transmission: ${commStatus!.dataTransmission?? 'NO DATA'}',
              style:
                  const TextStyle(color: FGColors.secondaryText, fontSize: 11)),
          if (commStatus!.connectionDuration!= null)
            Text('Connection Duration: ${commStatus!.connectionDuration}',
                style: const TextStyle(
                    color: FGColors.secondaryText, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _suppressionPanel() {
    if (suppressionStatus == null)
      return _genericPanel('Suppression System',
          height: 200,
          child: const Text(
              'No suppression data - connect fetchSuppressionStatus()',
              style: TextStyle(color: FGColors.secondaryText, fontSize: 11)));
    return _genericPanel(
      'Suppression System',
      height: 200,
      child: Row(
        children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                  'Suppression State: ${suppressionStatus!.suppressionState.name.toUpperCase()}',
                  style: const TextStyle(
                      color: FGColors.primaryText, fontSize: 11)),
              Text(
                  'Relay State: ${suppressionStatus!.relayState.name.toUpperCase()}',
                  style: const TextStyle(
                      color: FGColors.secondaryText, fontSize: 11)),
              Text(
                  'Last Activation: ${suppressionStatus!.lastActivation!= null? suppressionStatus!.lastActivation.toString() : 'NO DATA'}',
                  style: const TextStyle(
                      color: FGColors.secondaryText, fontSize: 11)),
              if (suppressionStatus!.duration!= null)
                Text('Duration: ${suppressionStatus!.duration}',
                    style: const TextStyle(
                        color: FGColors.secondaryText, fontSize: 11)),
            ]),
          ),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                  'System Readiness: ${suppressionStatus!.readiness?? 'NO DATA'}',
                  style:
                      const TextStyle(color: FGColors.warning, fontSize: 11)),
              Text(
                  'Last Diagnostic: ${suppressionStatus!.lastDiagnostic?? 'NO DATA'}',
                  style: const TextStyle(
                      color: FGColors.secondaryText, fontSize: 11)),
              if (suppressionStatus!.fault!= null)
                Text('Fault: ${suppressionStatus!.fault}',
                    style: const TextStyle(
                        color: FGColors.critical, fontSize: 11)),
              Text(
                  'Cartridge: ${suppressionStatus!.cartridgeStatus?? 'NO DATA'}',
                  style: const TextStyle(
                      color: FGColors.secondaryText, fontSize: 11)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _gpsLocationPanel() {
    if (gpsStatus == null) {
      return _genericPanel(
        'Capsule Location',
        height: 280,
        child: Column(children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
                color: FGColors.elevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: FGColors.border)),
            child: const Center(
                child: Text('GPS unavailable - connect fetchGpsStatus()',
                    style: TextStyle(
                        color: FGColors.secondaryText, fontSize: 11))),
          ),
          const SizedBox(height: 12),
          const Text('GPS unavailable',
              style: TextStyle(color: FGColors.critical, fontSize: 11)),
        ]),
      );
    }
    return _genericPanel(
      'Capsule Location',
      height: 300,
      trailing: TextButton(
          onPressed: () {},
          child: const Text('OPEN FULL MAP',
              style: TextStyle(color: FGColors.info, fontSize: 11))),
      child: Column(
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
                color: FGColors.elevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: FGColors.border)),
            child: Stack(
              children: [
                const Center(
                    child: Icon(Icons.map,
                        color: FGColors.secondaryText, size: 32)),
                if (gpsStatus!.latitude!= null)
                  Positioned.fill(
                      child: Center(
                          child: Icon(Icons.location_on,
                              color: FGColors.info, size: 28))),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'Latitude: ${gpsStatus!.latitude?.toString()?? 'NO DATA'}',
                        style: const TextStyle(
                            color: FGColors.secondaryText, fontSize: 11)),
                    Text(
                        'Longitude: ${gpsStatus!.longitude?.toString()?? 'NO DATA'}',
                        style: const TextStyle(
                            color: FGColors.secondaryText, fontSize: 11)),
                    Text('GPS Fix: ${gpsStatus!.fixStatus?? 'NO DATA'}',
                        style: const TextStyle(
                            color: FGColors.secondaryText, fontSize: 11)),
                    Text(
                        'Accuracy: ${gpsStatus!.accuracy!= null? '${gpsStatus!.accuracy}m' : 'NO DATA'}',
                        style: const TextStyle(
                            color: FGColors.secondaryText, fontSize: 11)),
                    Text(
                        'Last GPS Update: ${gpsStatus!.lastGpsUpdate!= null? _formatTimeAgo(gpsStatus!.lastGpsUpdate!) : 'NO DATA'}',
                        style: const TextStyle(
                            color: FGColors.secondaryText, fontSize: 11)),
                  ]),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _telemetryPanel() {
    return _genericPanel(
      'Sensor Telemetry',
      height: 340,
      trailing: Row(children: [
        DropdownButton<String>(
          value: selectedSensorId,
          dropdownColor: FGColors.elevated,
          style: const TextStyle(color: FGColors.primaryText, fontSize: 11),
          underline: const SizedBox(),
          items: const [
            DropdownMenuItem(value: 'flame_sensor', child: Text('Flame')),
            DropdownMenuItem(value: 'mq2', child: Text('Smoke/Gas')),
            DropdownMenuItem(value: 'mq7', child: Text('CO')),
            DropdownMenuItem(value: 'temperature', child: Text('Temperature')),
            DropdownMenuItem(value: 'humidity', child: Text('Humidity')),
            DropdownMenuItem(
                value: 'mlx90614', child: Text('Infrared Temperature')),
            DropdownMenuItem(value: 'battery', child: Text('Battery')),
            DropdownMenuItem(value: 'gsm_signal', child: Text('GSM Signal')),
          ],
          onChanged: (v) {
            if (v == null) return;
            setState(() => selectedSensorId = v);
            _loadTelemetry();
          },
        ),
        const SizedBox(width: 12),
        DropdownButton<String>(
          value: selectedTimeRange,
          dropdownColor: FGColors.elevated,
          style: const TextStyle(color: FGColors.primaryText, fontSize: 11),
          underline: const SizedBox(),
          items: const ['1 Hour', '6 Hours', '24 Hours', '7 Days', '30 Days']
             .map((e) => DropdownMenuItem(value: e, child: Text(e)))
             .toList(),
          onChanged: (v) {
            if (v == null) return;
            setState(() => selectedTimeRange = v);
            _loadTelemetry();
          },
        ),
      ]),
      child: telemetryLoading
         ? const Center(child: CircularProgressIndicator())
          : telemetryPoints.isEmpty
             ? const Center(
                  child: Text(
                      'No telemetry - backend returns empty until real historical data exists',
                      style: TextStyle(
                          color: FGColors.secondaryText, fontSize: 11)))
              : SizedBox(
                  height: 220,
                  child: CustomPaint(
                      painter: TelemetryPainter(points: telemetryPoints),
                      child: Container())),
    );
  }

  Widget _recentAlertsPanel() {
    if (alerts.isEmpty)
      return _genericPanel('Recent Alerts',
          height: 160,
          trailing: TextButton(
              onPressed: () {},
              child: const Text('VIEW ALL ALERTS',
                  style: TextStyle(color: FGColors.info, fontSize: 11))),
          child: const Text(
              'No alerts from backend - connect fetchRecentAlerts() and liveAlertStream',
              style: TextStyle(color: FGColors.secondaryText, fontSize: 11)));
    return _genericPanel(
      'Recent Alerts',
      trailing: TextButton(
          onPressed: () {},
          child: const Text('VIEW ALL ALERTS',
              style: TextStyle(color: FGColors.info, fontSize: 11))),
      child: Column(
        children: alerts.take(5).map((a) {
          Color c;
          switch (a.severity) {
            case Severity.info:
              c = FGColors.info;
              break;
            case Severity.warning:
              c = FGColors.warning;
              break;
            case Severity.error:
            case Severity.critical:
              c = FGColors.critical;
              break;
            case Severity.success:
              c = FGColors.healthy;
              break;
          }
          return Container(
            height: 80,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
                color: FGColors.elevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: FGColors.border)),
            child: ListTile(
              leading: Icon(Icons.warning, color: c, size: 20),
              title: Text(a.title,
                  style: const TextStyle(
                      color: FGColors.primaryText, fontSize: 12)),
              subtitle: Text(
                  '${a.component} • ${a.detectionTime!= null? _formatTimeAgo(a.detectionTime!) : 'NO DATA'}',
                  style: const TextStyle(
                      color: FGColors.secondaryText, fontSize: 11)),
              trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: FGColors.border,
                      borderRadius: BorderRadius.circular(4)),
                  child: Text(a.status,
                      style: const TextStyle(
                          color: FGColors.secondaryText, fontSize: 10))),
              onTap: () {},
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _maintenancePanel() {
    if (maintenanceStatus == null)
      return _genericPanel('Maintenance Status',
          height: 160,
          child: const Text(
              'No maintenance data - connect fetchMaintenanceStatus()',
              style: TextStyle(color: FGColors.secondaryText, fontSize: 11)));
    String state = maintenanceStatus!.maintenanceState?? 'NO DATA';
    Color stateColor = state == 'UP TO DATE'
       ? FGColors.healthy
        : state == 'DUE SOON'
           ? FGColors.warning
            : state == 'OVERDUE'
               ? FGColors.critical
                : FGColors.secondaryText;
    return _genericPanel(
      'Maintenance Status',
      child: Wrap(
        spacing: 24,
        runSpacing: 8,
        children: [
          Text(
              'Installation date: ${maintenanceStatus!.installationDate?.toString()?? 'NO DATA'}',
              style:
                  const TextStyle(color: FGColors.secondaryText, fontSize: 11)),
          Text(
              'Last maintenance: ${maintenanceStatus!.lastMaintenance?.toString()?? 'NO DATA'}',
              style:
                  const TextStyle(color: FGColors.secondaryText, fontSize: 11)),
          Text(
              'Next maintenance: ${maintenanceStatus!.nextMaintenance?.toString()?? 'NO DATA'}',
              style:
                  const TextStyle(color: FGColors.secondaryText, fontSize: 11)),
          Text(
              'Sensor calibration: ${maintenanceStatus!.sensorCalibration?.toString()?? 'NO DATA'}',
              style:
                  const TextStyle(color: FGColors.secondaryText, fontSize: 11)),
          Text(
              'Hardware condition: ${maintenanceStatus!.hardwareCondition?? 'NO DATA'}',
              style:
                  const TextStyle(color: FGColors.secondaryText, fontSize: 11)),
          Text(
              'Firmware version: ${maintenanceStatus!.firmwareVersion?? 'NO DATA'}',
              style:
                  const TextStyle(color: FGColors.secondaryText, fontSize: 11)),
          Text(
              'Suppression inspection: ${maintenanceStatus!.suppressionInspection?.toString()?? 'NO DATA'}',
              style:
                  const TextStyle(color: FGColors.secondaryText, fontSize: 11)),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: stateColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4)),
              child: Text(state,
                  style: TextStyle(
                      color: stateColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _activityHistoryPanel() {
    if (activityEvents.isEmpty)
      return _genericPanel('Capsule Activity',
          height: 200,
          child: const Text(
              'No activity history - connect fetchActivityHistory()',
              style: TextStyle(color: FGColors.secondaryText, fontSize: 11)));
    return _genericPanel(
      'Capsule Activity',
      child: Column(
        children: activityEvents
           .map((e) => ListTile(
                leading:
                    Container(width: 2, height: 32, color: FGColors.border),
                title: Text(e.description,
                    style: const TextStyle(
                        color: FGColors.primaryText, fontSize: 12)),
                subtitle: Text(
                    '${e.timestamp} • ${e.eventType} • ${e.userOrSystem?? 'System'} • ${e.result?? ''}',
                    style: const TextStyle(
                        color: FGColors.secondaryText, fontSize: 10))))
           .toList(),
      ),
    );
  }

  Widget _capsuleActionsPanel(bool isMobile) {
    final actions = [
      {'label': 'Open on Map', 'icon': Icons.map, 'perm': true},
      {
        'label': 'Run Diagnostics',
        'icon': Icons.health_and_safety,
        'perm': permissions?.canDiagnose?? false
      },
      {
        'label': 'Test Sensors',
        'icon': Icons.sensors,
        'perm': permissions?.canTest?? false
      },
      {'label': 'Refresh Data', 'icon': Icons.refresh, 'perm': true},
      {
        'label': 'Configure Capsule',
        'icon': Icons.settings,
        'perm': permissions?.canConfigure?? false
      },
      {
        'label': 'Update Firmware',
        'icon': Icons.system_update,
        'perm': permissions?.canUpdateFirmware?? false
      },
      {
        'label': 'Schedule Maintenance',
        'icon': Icons.build,
        'perm': permissions?.canScheduleMaintenance?? false
      },
    ];
    return _genericPanel(
      'Capsule Actions',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: actions.where((a) => a['perm'] == true).map((a) {
          return _actionButton(a['label'] as String, a['icon'] as IconData,
              primary: false,
              enabled:!_actionInProgress,
              onTap: () => _executeAction(a['label'] as String));
        }).toList(),
      ),
    );
  }

  Widget _buildSystemHealthScroll(bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Current System Health'),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: isMobile? 2 : 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.6,
            children: [
              _healthCard(
                  'Capsules',
                  'Online / Total',
                  systemHealth!= null
                     ? '${systemHealth!.capsulesOnline?? 0} / ${systemHealth!.capsulesTotal?? 0}'
                      : 'NO DATA'),
              _healthCard(
                  'Sensors',
                  'Operational / Total',
                  systemHealth!= null
                     ? '${systemHealth!.sensorsOperational?? 0} / ${systemHealth!.sensorsTotal?? 0}'
                      : 'NO DATA'),
              _healthCard(
                  'Communication',
                  'Healthy / Degraded / Offline',
                  systemHealth!= null
                     ? '${systemHealth!.commHealthy?? 0} / ${systemHealth!.commDegraded?? 0} / ${systemHealth!.commOffline?? 0}'
                      : 'NO DATA'),
              _healthCard('Power', 'Healthy / Warning / Critical',
                  systemHealth?.powerSummary?? 'NO DATA'),
            ],
          ),
          const SizedBox(height: 20),
          _genericPanel(
            'Component Health',
            child: systemHealthLoading
               ? _skeleton(height: 200)
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor:
                          WidgetStateProperty.all(FGColors.elevated),
                      columns: const [
                        DataColumn(
                            label: Text('Component',
                                style: TextStyle(
                                    color: FGColors.secondaryText,
                                    fontSize: 11))),
                        DataColumn(
                            label: Text('Status',
                                style: TextStyle(
                                    color: FGColors.secondaryText,
                                    fontSize: 11))),
                        DataColumn(
                            label: Text('Last Reading',
                                style: TextStyle(
                                    color: FGColors.secondaryText,
                                    fontSize: 11))),
                        DataColumn(
                            label: Text('Last Diagnostic',
                                style: TextStyle(
                                    color: FGColors.secondaryText,
                                    fontSize: 11))),
                      ],
                      rows: deviceHealth.isEmpty
                         ? [
                              const DataRow(cells: [
                                DataCell(Text(
                                    'No data - connect fetchDeviceHealth',
                                    style: TextStyle(
                                        color: FGColors.secondaryText,
                                        fontSize: 11))),
                                DataCell(Text('NO DATA')),
                                DataCell(Text('--')),
                                DataCell(Text('--'))
                              ])
                            ]
                          : deviceHealth
                             .map((h) => DataRow(cells: [
                                    DataCell(Text(h.componentName,
                                        style: const TextStyle(
                                            color: FGColors.primaryText,
                                            fontSize: 11))),
                                    DataCell(Text(h.status.name,
                                        style: const TextStyle(
                                            color: FGColors.secondaryText,
                                            fontSize: 11))),
                                    DataCell(Text(
                                        h.lastCommunication!= null
                                           ? _formatTimeAgo(
                                                h.lastCommunication!)
                                            : 'NO DATA',
                                        style: const TextStyle(
                                            color: FGColors.secondaryText,
                                            fontSize: 11))),
                                    DataCell(Text(
                                        h.lastDiagnostic!= null
                                           ? _formatTimeAgo(h.lastDiagnostic!)
                                            : 'NO DATA',
                                        style: const TextStyle(
                                            color: FGColors.secondaryText,
                                            fontSize: 11)))
                                  ]))
                             .toList(),
                    ),
                  ),
          ),
          const SizedBox(height: 20),
          _genericPanel(
            'System Logs',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (logsLoading)
                  _skeleton(height: 200)
                else if (systemLogs.isEmpty)
                  const Text('No logs - connect fetchSystemLogs()',
                      style: TextStyle(
                          color: FGColors.secondaryText, fontSize: 11))
                else
                  SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Timestamp')),
                            DataColumn(label: Text('Capsule ID')),
                            DataColumn(label: Text('Component')),
                            DataColumn(label: Text('Event')),
                            DataColumn(label: Text('Severity')),
                            DataColumn(label: Text('Status'))
                          ],
                          rows: systemLogs
                             .map((l) => DataRow(cells: [
                                    DataCell(Text(l.timestamp.toString(),
                                        style: const TextStyle(fontSize: 11))),
                                    DataCell(Text(l.capsuleId)),
                                    DataCell(Text(l.component)),
                                    DataCell(Text(l.event)),
                                    DataCell(Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                            color: _severityColor(l.severity)
                                               .withOpacity(0.15),
                                            borderRadius:
                                                BorderRadius.circular(4)),
                                        child: Text(
                                            l.severity.name.toUpperCase(),
                                            style: TextStyle(
                                                color:
                                                    _severityColor(l.severity),
                                                fontSize: 10)))),
                                    DataCell(Text(l.status))
                                  ]))
                             .toList())),
                const SizedBox(height: 8),
                const Text(
                    'Severity colors: INFO #4DA3FF WARNING #FFB547 ERROR #FF4D3D CRITICAL #FF4D3D SUCCESS #25C281 - only badge colored',
                    style:
                        TextStyle(color: FGColors.secondaryText, fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _genericPanel('Fire Event History',
              height: 160,
              child: const Text(
                  'No fire events - connect fetchFireEventHistory() from backend event store',
                  style:
                      TextStyle(color: FGColors.secondaryText, fontSize: 11))),
          const SizedBox(height: 20),
          _genericPanel(
            'System Performance Validation',
            child: Column(
              children: [
                'Fire detection accuracy',
                'False alarm rate',
                'Detection-to-verification time',
                'Verification-to-response time',
                'Alert delivery success',
                'System uptime',
                'Suppression activation success',
                'Suppression effectiveness'
              ]
                 .map((m) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(children: [
                        Expanded(
                            child: Text(m,
                                style: const TextStyle(
                                    color: FGColors.primaryText,
                                    fontSize: 11))),
                        const Text(
                            'Target: from config | Actual: from testing/system data',
                            style: TextStyle(
                                color: FGColors.secondaryText, fontSize: 11))
                      ])))
                 .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _healthCard(String title, String subtitle, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: FGColors.panel,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: FGColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                color: FGColors.primaryText,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(subtitle,
            style:
                const TextStyle(color: FGColors.secondaryText, fontSize: 10)),
        const Spacer(),
        Text(value,
            style: const TextStyle(color: FGColors.primaryText, fontSize: 12)),
      ]),
    );
  }

  Widget _genericPanel(String title,
      {double? height, Widget? trailing, required Widget child}) {
    return Container(
      width: double.infinity,
      constraints: height!= null? BoxConstraints(minHeight: height) : null,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: FGColors.panel,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: FGColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: FGColors.primaryText)),
            const Spacer(),
            if (trailing!= null) trailing
          ]),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: FGColors.primaryText));
  Widget _skeleton({required double height}) => Container(
      height: height,
      decoration: BoxDecoration(
          color: FGColors.panel,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: FGColors.border)),
      child: const Center(
          child: Text('Loading capsule data...',
              style: TextStyle(color: FGColors.secondaryText, fontSize: 12))));
  Widget _emptyState(String msg) => Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: FGColors.panel,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: FGColors.border)),
      child: Center(
          child: Text(msg,
              style:
                  const TextStyle(color: FGColors.secondaryText, fontSize: 12),
              textAlign: TextAlign.center)));
  Widget _errorState(String msg, {required VoidCallback onRetry}) => Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: FGColors.panel,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: FGColors.critical)),
      child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(msg,
            style: const TextStyle(color: FGColors.critical, fontSize: 12),
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(backgroundColor: FGColors.elevated),
            child: const Text('Retry'))
      ])));

  Widget _actionButton(String label, IconData icon,
      {bool primary = true, bool enabled = true, VoidCallback? onTap}) {
    return SizedBox(
      height: 44,
      child: ElevatedButton.icon(
        onPressed: enabled &&!_actionInProgress? onTap : null,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: ElevatedButton.styleFrom(
            backgroundColor: primary? FGColors.info : FGColors.elevated,
            foregroundColor: FGColors.primaryText,
            disabledBackgroundColor: FGColors.border,
            side: const BorderSide(color: FGColors.border),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      ),
    );
  }

  void _showMoreMenu() {
    showModalBottomSheet(
        context: context,
        backgroundColor: FGColors.panel,
        builder: (_) => SafeArea(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              ListTile(
                  leading:
                      const Icon(Icons.settings, color: FGColors.primaryText),
                  title: const Text('Configure Capsule',
                      style: TextStyle(color: FGColors.primaryText)),
                  onTap: () => Navigator.pop(context)),
              ListTile(
                  leading: const Icon(Icons.system_update,
                      color: FGColors.primaryText),
                  title: const Text('Update Firmware',
                      style: TextStyle(color: FGColors.primaryText)),
                  onTap: () => Navigator.pop(context))
            ])));
  }

  Future<void> _executeAction(String action) async {
    if (_actionInProgress) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: FGColors.panel,
        title:
            Text(action, style: const TextStyle(color: FGColors.primaryText)),
        content: Text(
            'This operation will affect physical capsule ${widget.capsuleId}. Backend will verify safety checks, hardware state, and authorization before execution. Confirm?',
            style:
                const TextStyle(color: FGColors.secondaryText, fontSize: 12)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel',
                  style: TextStyle(color: FGColors.secondaryText))),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: FGColors.info),
              child: const Text('Confirm')),
        ],
      ),
    );
    if (confirmed!= true) return;
    setState(() => _actionInProgress = true);
    try {
      ActionResult result;
      switch (action) {
        case 'Run Diagnostics':
          result = await _repo.runDiagnostics(widget.capsuleId);
          break;
        case 'Test Sensors':
          result = await _repo.testSensors(widget.capsuleId);
          break;
        case 'Refresh Data':
          result = await _repo.refreshData(widget.capsuleId);
          await _startSequentialLoad();
          break;
        case 'Configure Capsule':
          result = await _repo.configureCapsule(widget.capsuleId);
          break;
        case 'Update Firmware':
          result = await _repo.updateFirmware(widget.capsuleId);
          break;
        case 'Schedule Maintenance':
          result = await _repo.scheduleMaintenance(widget.capsuleId);
          break;
        default:
          result =
              const ActionResult(success: false, message: 'Unknown action');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result.message),
          backgroundColor:
              result.success? FGColors.healthy : FGColors.critical));
      await _loadActivity();
    } finally {
      if (mounted) setState(() => _actionInProgress = false);
    }
  }

  void _confirmAction(String label) => _executeAction(label);

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 30) return 'Updated ${diff.inSeconds} seconds ago';
    if (diff.inSeconds < 120) return 'Last reading ${diff.inSeconds} sec ago';
    if (diff.inMinutes < 5) return 'Last reading ${diff.inMinutes} min ago';
    if (diff.inMinutes < 30)
      return 'Updated ${diff.inMinutes} min ago - DATA DELAYED';
    if (diff.inHours < 24)
      return 'Last reading ${diff.inHours}h ago - DEGRADED';
    return 'DATA STALE - Last reading ${diff.inHours}h ago';
  }

  Color _severityColor(Severity s) {
    switch (s) {
      case Severity.info:
        return FGColors.info;
      case Severity.warning:
        return FGColors.warning;
      case Severity.error:
      case Severity.critical:
        return FGColors.critical;
      case Severity.success:
        return FGColors.healthy;
    }
  }

  Widget _buildBottomNav() {
    return Container(
      height: 68,
      decoration: const BoxDecoration(
          color: FGColors.panel,
          border: Border(top: BorderSide(color: FGColors.border))),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _bottomItem(Icons.sensors, 'Capsule', true, 0),
        _bottomItem(Icons.map, 'Map', false, 0),
        _bottomItem(Icons.assessment, 'Health', false, 1),
        _bottomItem(Icons.person, 'Profile', false, 0),
      ]),
    );
  }

  Widget _bottomItem(IconData icon, String label, bool selected, int tabIndex) {
    return InkWell(
      onTap: () {
        if (tabIndex == 1) _tabController.animateTo(1);
        if (tabIndex == 0) _tabController.animateTo(0);
      },
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon,
            color: selected? FGColors.info : FGColors.secondaryText, size: 22),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                color: selected? FGColors.info : FGColors.secondaryText,
                fontSize: 10)),
      ]),
    );
  }
}

class TelemetryPainter extends CustomPainter {
  final List<TelemetryPoint> points;
  TelemetryPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final gridPaint = Paint()
     ..color = FGColors.border
     ..strokeWidth = 0.5;
    for (int i = 0; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    final minVal = points.map((p) => p.value).reduce((a, b) => a < b? a : b);
    final maxVal = points.map((p) => p.value).reduce((a, b) => a > b? a : b);
    final range = (maxVal - minVal) == 0? 1 : (maxVal - minVal);
    final path = Path();
    final linePaint = Paint()
     ..color = FGColors.info
     ..strokeWidth = 2
     ..style = PaintingStyle.stroke;
    for (int i = 0; i < points.length; i++) {
      final x = size.width * i / (points.length - 1);
      final normalized = (points[i].value - minVal) / range;
      final y = size.height - (normalized * size.height);
      if (i == 0)
        path.moveTo(x, y);
      else
        path.lineTo(x, y);
    }
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant TelemetryPainter oldDelegate) =>
      oldDelegate.points!= points;
}