import 'dart:async';

enum FireSeverity {
  low,
  medium,
  high,
  critical,
}

enum CapsuleStatus {
  operational,
  warning,
  critical,
  offline,
}

class FireIncident {
  final String id;
  final FireSeverity severity;
  final double lat;
  final double lng;

  final DateTime? detectedAt;
  final double? areaHa;
  final double? temperature;
  final double? humidity;
  final double? windSpeed;

  final String? windDir;
  final String? spreadDir;

  final DateTime? lastUpdated;

  final List<LatLngPoint>? perimeter;
  final List<LatLngPoint>? predictedSpread;

  FireIncident({
    required this.id,
    required this.severity,
    required this.lat,
    required this.lng,
    this.detectedAt,
    this.areaHa,
    this.temperature,
    this.humidity,
    this.windSpeed,
    this.windDir,
    this.spreadDir,
    this.lastUpdated,
    this.perimeter,
    this.predictedSpread,
  });

  factory FireIncident.fromJson(Map<String, dynamic> json) {
    return FireIncident(
      id: json['id']?.toString() ?? 'UNKNOWN',

      severity: _parseFireSeverity(
        json['severity']?.toString(),
      ),

      lat: _toDouble(
            json['lat'] ?? json['latitude'],
          ) ??
          0.0,

      lng: _toDouble(
            json['lng'] ?? json['longitude'],
          ) ??
          0.0,

      // Backend currently returns "detectionTime".
      detectedAt: _toDateTime(
        json['detected_at'] ??
            json['detectedAt'] ??
            json['detectionTime'] ??
            json['detected_time'],
      ),

      areaHa: _toDouble(
        json['area_ha'] ?? json['areaHa'],
      ),

      temperature: _toDouble(
        json['temperature'],
      ),

      humidity: _toDouble(
        json['humidity'],
      ),

      windSpeed: _toDouble(
        json['wind_speed'] ?? json['windSpeed'],
      ),

      windDir: _toStringOrNull(
        json['wind_dir'] ?? json['windDir'],
      ),

      spreadDir: _toStringOrNull(
        json['spread_dir'] ?? json['spreadDir'],
      ),

      lastUpdated: _toDateTime(
        json['last_updated'] ??
            json['lastUpdated'] ??
            json['updated_at'],
      ),

      perimeter: _parsePoints(
        json['perimeter'],
      ),

      predictedSpread: _parsePoints(
        json['predicted_spread'] ??
            json['predictedSpread'],
      ),
    );
  }
}

class CapsuleDevice {
  final String id;
  final CapsuleStatus status;

  final double lat;
  final double lng;

  final double? battery;
  final double? temperature;

  final String? network;
  final String? solarStatus;

  final DateTime? lastComm;

  CapsuleDevice({
    required this.id,
    required this.status,
    required this.lat,
    required this.lng,
    this.battery,
    this.temperature,
    this.network,
    this.solarStatus,
    this.lastComm,
  });

  factory CapsuleDevice.fromJson(
    Map<String, dynamic> json,
  ) {
    return CapsuleDevice(
      id: json['id']?.toString() ??
          json['capsule_id']?.toString() ??
          json['capsule_code']?.toString() ??
          'UNKNOWN',

      status: _parseCapsuleStatus(
        json['status']?.toString(),
      ),

      lat: _toDouble(
            json['lat'] ??
                json['latitude'],
          ) ??
          0.0,

      lng: _toDouble(
            json['lng'] ??
                json['longitude'],
          ) ??
          0.0,

      battery: _toDouble(
        json['battery'] ??
            json['battery_level'],
      ),

      temperature: _toDouble(
        json['temperature'],
      ),

      network: _toStringOrNull(
        json['network'] ??
            json['network_status'] ??
            json['communication_status'],
      ),

      solarStatus: _toStringOrNull(
        json['solar_status'] ??
            json['solarStatus'],
      ),

      lastComm: _toDateTime(
        json['last_comm'] ??
            json['last_communication'] ??
            json['lastCommunication'],
      ),
    );
  }
}

class LatLngPoint {
  final double lat;
  final double lng;

  LatLngPoint(
    this.lat,
    this.lng,
  );

  factory LatLngPoint.fromJson(
    Map<String, dynamic> json,
  ) {
    return LatLngPoint(
      _toDouble(
            json['lat'] ??
                json['latitude'],
          ) ??
          0.0,
      _toDouble(
            json['lng'] ??
                json['longitude'],
          ) ??
          0.0,
    );
  }
}

enum DataConnectionState {
  loading,
  live,
  offline,
  error,
  stale,
  empty,
}

class MapDataController {
  final _capsulesCtrl =
      StreamController<List<CapsuleDevice>>.broadcast();

  final _firesCtrl =
      StreamController<List<FireIncident>>.broadcast();

  final _metricsCtrl =
      StreamController<Map<String, dynamic>>.broadcast();

  final _connCtrl =
      StreamController<DataConnectionState>.broadcast();

  Stream<List<CapsuleDevice>> get capsulesStream =>
      _capsulesCtrl.stream;

  Stream<List<FireIncident>> get firesStream =>
      _firesCtrl.stream;

  Stream<Map<String, dynamic>> get metricsStream =>
      _metricsCtrl.stream;

  Stream<DataConnectionState> get connectionStream =>
      _connCtrl.stream;

  List<CapsuleDevice> currentCapsules = [];

  List<FireIncident> currentFires = [];

  Map<String, dynamic> currentMetrics = {};

  void updateCapsules(
    List<CapsuleDevice> data,
  ) {
    currentCapsules = data;

    _capsulesCtrl.add(data);
  }

  void updateFires(
    List<FireIncident> data,
  ) {
    currentFires = data;

    _firesCtrl.add(data);

    if (data.isEmpty) {
      _connCtrl.add(
        DataConnectionState.empty,
      );
    } else {
      _connCtrl.add(
        DataConnectionState.live,
      );
    }
  }

  void updateMetrics(
    Map<String, dynamic> data,
  ) {
    currentMetrics = data;

    _metricsCtrl.add(data);
  }

  void updateConnection(
    DataConnectionState state,
  ) {
    _connCtrl.add(state);
  }

  void dispose() {
    _capsulesCtrl.close();
    _firesCtrl.close();
    _metricsCtrl.close();
    _connCtrl.close();
  }
}

double? _toDouble(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is num) {
    return value.toDouble();
  }

  if (value is String) {
    return double.tryParse(value.trim());
  }

  return null;
}

String? _toStringOrNull(dynamic value) {
  if (value == null) {
    return null;
  }

  final result = value.toString().trim();

  if (result.isEmpty) {
    return null;
  }

  return result;
}

DateTime? _toDateTime(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is DateTime) {
    return value;
  }

  return DateTime.tryParse(
    value.toString(),
  );
}

FireSeverity _parseFireSeverity(
  String? value,
) {
  switch (value?.toLowerCase()) {
    case 'low':
      return FireSeverity.low;

    case 'medium':
      return FireSeverity.medium;

    case 'high':
      return FireSeverity.high;

    case 'critical':
      return FireSeverity.critical;

    default:
      return FireSeverity.medium;
  }
}

CapsuleStatus _parseCapsuleStatus(
  String? value,
) {
  switch (value?.toLowerCase()) {
    case 'operational':
    case 'online':
      return CapsuleStatus.operational;

    case 'warning':
      return CapsuleStatus.warning;

    case 'critical':
      return CapsuleStatus.critical;

    case 'offline':
      return CapsuleStatus.offline;

    default:
      return CapsuleStatus.offline;
  }
}

List<LatLngPoint>? _parsePoints(
  dynamic value,
) {
  if (value is! List) {
    return null;
  }

  final points = <LatLngPoint>[];

  for (final item in value) {
    if (item is Map<String, dynamic>) {
      points.add(
        LatLngPoint.fromJson(item),
      );
    }
  }

  return points.isEmpty ? null : points;
}