import 'antenna_config.dart';
import 'radio_config.dart';

enum BasePointSource { knownPoint, averaged, manual }

enum BaseSessionState { idle, configuring, running, stopped, error }

/// Base operates on the EXTERNAL GNSS receiver, not the Android controller.
class BaseSession {
  static final BaseSession instance = BaseSession._();
  BaseSession._();

  BaseSessionState state = BaseSessionState.idle;
  BasePointSource pointSource = BasePointSource.manual;

  String? pointId;
  String? pointName;
  double? latitude;
  double? longitude;
  double? elevation;

  AntennaConfig antenna = AntennaConfig();
  RadioConfig radio = RadioConfig();
  String correctionFormat = 'rtcm3'; // rtcm3 | rtcm2 | cmr | oem
  String correctionOutput = 'none'; // radio | network | serial | bluetooth | tcp | none

  DateTime? startedAt;
  int rtcmBytesOut = 0;
  int rtcmMessagesOut = 0;
  String? lastError;
  String? receiverName;

  bool get hasValidCoordinates =>
      latitude != null && longitude != null && elevation != null;

  bool get canStart {
    if (state == BaseSessionState.running) return false;
    if (!hasValidCoordinates) return false;
    if (antenna.heightM < 0) return false;
    return true;
  }

  Duration? get elapsed =>
      startedAt == null ? null : DateTime.now().difference(startedAt!);

  void setKnownPoint({
    required String id,
    required String name,
    required double lat,
    required double lon,
    required double elev,
  }) {
    pointSource = BasePointSource.knownPoint;
    pointId = id;
    pointName = name;
    latitude = lat;
    longitude = lon;
    elevation = elev;
  }

  void setManual(double lat, double lon, double elev) {
    pointSource = BasePointSource.manual;
    pointId = null;
    pointName = 'MANUAL';
    latitude = lat;
    longitude = lon;
    elevation = elev;
  }

  void setAveraged(double lat, double lon, double elev) {
    pointSource = BasePointSource.averaged;
    pointId = null;
    pointName = 'AVG';
    latitude = lat;
    longitude = lon;
    elevation = elev;
  }

  /// Start base session on controller side.
  /// Actual receiver BASE mode requires OEM/NMEA support on the external unit.
  bool start({required String receiverLabel, required bool receiverConnected}) {
    if (!canStart) {
      lastError = 'Missing coordinates or invalid antenna';
      return false;
    }
    if (!receiverConnected) {
      lastError = 'External GNSS receiver not connected';
      return false;
    }
    state = BaseSessionState.running;
    startedAt = DateTime.now();
    receiverName = receiverLabel;
    rtcmBytesOut = 0;
    rtcmMessagesOut = 0;
    lastError = null;
    return true;
  }

  void stop() {
    state = BaseSessionState.stopped;
    startedAt = null;
  }

  void reset() {
    state = BaseSessionState.idle;
    startedAt = null;
    rtcmBytesOut = 0;
    rtcmMessagesOut = 0;
    lastError = null;
  }

  Map<String, String> summary() => {
        'Point': pointName ?? pointId ?? '--',
        'Latitude': latitude?.toStringAsFixed(8) ?? '--',
        'Longitude': longitude?.toStringAsFixed(8) ?? '--',
        'Elevation': elevation != null ? '${elevation!.toStringAsFixed(3)} m' : '--',
        'Antenna H': '${antenna.heightM.toStringAsFixed(3)} m (${antenna.measureType})',
        'Format': correctionFormat.toUpperCase(),
        'Output': correctionOutput,
        'Radio': radio.radioType,
        'Receiver': receiverName ?? '--',
        'State': state.name.toUpperCase(),
      };
}
