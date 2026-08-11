import 'dart:async';
import 'connection_types.dart';
import '../services/gnss_service.dart';

/// Central connection coordinator. UI should use this instead of hardware APIs.
class ConnectionManager {
  static final ConnectionManager _instance = ConnectionManager._();
  factory ConnectionManager() => _instance;
  ConnectionManager._();

  final GnssService _gnss = GnssService();
  ConnectionType _activeType = ConnectionType.internalGnss;
  ConnectionState _state = ConnectionState.disconnected;

  int bytesReceived = 0;
  int bytesTransmitted = 0;
  DateTime? lastDataAt;
  bool nmeaDetected = false;
  bool rtcmDetected = false;
  bool gnssVerified = false;
  bool rtkVerified = false;

  final _stateController = StreamController<ConnectionState>.broadcast();
  Stream<ConnectionState> get stateStream => _stateController.stream;

  ConnectionType get activeType => _activeType;
  ConnectionState get state => _state;
  bool get isGnssLinked => _gnss.isConnected || _activeType == ConnectionType.internalGnss;

  void _setState(ConnectionState s) {
    _state = s;
    _stateController.add(s);
  }

  void selectTransport(ConnectionType type) {
    _activeType = type;
  }

  /// Mark that raw bytes arrived on the active transport.
  void onRawData(List<int> data, {bool isRtcm = false}) {
    bytesReceived += data.length;
    lastDataAt = DateTime.now();
    if (_state == ConnectionState.connected ||
        _state == ConnectionState.connecting ||
        _state == ConnectionState.discovered) {
      _setState(ConnectionState.dataDetected);
    }
    if (isRtcm) {
      rtcmDetected = true;
    } else {
      // Heuristic: NMEA lines start with $
      final asStr = String.fromCharCodes(data);
      if (asStr.contains('\$GP') || asStr.contains('\$GN') || asStr.contains('\$GL')) {
        nmeaDetected = true;
      }
    }
  }

  void onGnssPositionValid({required bool isRtk}) {
    gnssVerified = true;
    _setState(ConnectionState.gnssVerified);
    if (isRtk) {
      rtkVerified = true;
      _setState(ConnectionState.rtkVerified);
    }
  }

  void onConnected() => _setState(ConnectionState.connected);
  void onDisconnected() {
    _setState(ConnectionState.disconnected);
    nmeaDetected = false;
    rtcmDetected = false;
    gnssVerified = false;
    rtkVerified = false;
  }

  void onError() => _setState(ConnectionState.error);

  Map<String, dynamic> diagnosticsSnapshot() {
    return {
      'transport': _activeType.label,
      'state': _state.label,
      'bytesReceived': bytesReceived,
      'bytesTransmitted': bytesTransmitted,
      'lastDataAt': lastDataAt?.toIso8601String(),
      'nmeaDetected': nmeaDetected,
      'rtcmDetected': rtcmDetected,
      'gnssVerified': gnssVerified,
      'rtkVerified': rtkVerified,
      'deviceName': _gnss.connectedDeviceName,
    };
  }

  void dispose() {
    _stateController.close();
  }
}
