import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../hal/connection_manager.dart';

class NtripService {
  static final NtripService _instance = NtripService._internal();
  factory NtripService() => _instance;
  NtripService._internal();

  Socket? _socket;
  bool _isConnected = false;
  String? _currentCaster;
  String? _currentMountpoint;
  DateTime? _connectedAt;
  int rtcmBytesReceived = 0;
  int rtcmMessageCount = 0;
  double? lastCorrectionAgeSec;
  bool autoReconnect = true;
  int reconnectDelaySec = 5;
  bool sendGga = true;
  int ggaIntervalSec = 5;
  Timer? _ggaTimer;
  Timer? _reconnectTimer;
  String? _host;
  int? _port;
  String? _user;
  String? _pass;
  String? _mount;

  final _statusController = StreamController<String>.broadcast();
  Stream<String> get statusStream => _statusController.stream;

  bool get isConnected => _isConnected;
  String? get caster => _currentCaster;
  String? get mountpoint => _currentMountpoint;
  Duration? get connectionDuration =>
      _connectedAt == null ? null : DateTime.now().difference(_connectedAt!);

  Future<bool> connect({
    required String host,
    required int port,
    required String mountpoint,
    String username = '',
    String password = '',
  }) async {
    _host = host;
    _port = port;
    _mount = mountpoint;
    _user = username;
    _pass = password;
    return _doConnect();
  }

  Future<bool> _doConnect() async {
    try {
      await disconnect(reconnect: false);
      _socket = await Socket.connect(_host!, _port!, timeout: const Duration(seconds: 10));
      _currentCaster = _host;
      _currentMountpoint = _mount;

      final auth = (_user != null && _user!.isNotEmpty)
          ? 'Authorization: Basic ${base64Encode(utf8.encode('$_user:$_pass'))}\r\n'
          : '';

      final request = 'GET /$_mount HTTP/1.0\r\n'
          'User-Agent: NTRIP GeoMaster/1.4\r\n'
          'Accept: */*\r\n'
          '$auth'
          'Connection: close\r\n\r\n';

      _socket!.write(request);
      await _socket!.flush();
      ConnectionManager().bytesTransmitted += request.length;

      _socket!.listen(
        (data) {
          rtcmBytesReceived += data.length;
          rtcmMessageCount += 1;
          ConnectionManager().onRawData(data, isRtcm: true);
          if (!_isConnected) {
            _isConnected = true;
            _connectedAt = DateTime.now();
            _statusController.add('connected');
            ConnectionManager().onConnected();
          }
        },
        onError: (e) {
          _isConnected = false;
          _statusController.add('error: $e');
          ConnectionManager().onError();
          _scheduleReconnect();
        },
        onDone: () {
          _isConnected = false;
          _statusController.add('disconnected');
          ConnectionManager().onDisconnected();
          _scheduleReconnect();
        },
      );

      await Future.delayed(const Duration(seconds: 2));
      if (!_isConnected) {
        _isConnected = true;
        _connectedAt = DateTime.now();
        _statusController.add('connected');
      }
      _startGgaTimer();
      return true;
    } catch (e) {
      _isConnected = false;
      _statusController.add('error: $e');
      _scheduleReconnect();
      return false;
    }
  }

  void _startGgaTimer() {
    _ggaTimer?.cancel();
    if (!sendGga) return;
    _ggaTimer = Timer.periodic(Duration(seconds: ggaIntervalSec), (_) {
      // GGA forwarding requires a valid position from engine; best-effort placeholder skip if none
    });
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    if (!autoReconnect || _host == null) return;
    _reconnectTimer = Timer(Duration(seconds: reconnectDelaySec), () {
      _doConnect();
    });
  }

  /// Optional: feed GGA sentence to caster (NTRIP client duty for VRS).
  void sendGgaSentence(String ggaNmea) {
    if (!_isConnected || _socket == null || !sendGga) return;
    try {
      _socket!.write(ggaNmea.endsWith('\r\n') ? ggaNmea : '$ggaNmea\r\n');
      ConnectionManager().bytesTransmitted += ggaNmea.length;
    } catch (_) {}
  }

  Future<void> disconnect({bool reconnect = true}) async {
    if (!reconnect) {
      autoReconnect = false;
      _reconnectTimer?.cancel();
    }
    _ggaTimer?.cancel();
    try {
      await _socket?.close();
    } catch (_) {}
    _socket = null;
    _isConnected = false;
    _currentCaster = null;
    _currentMountpoint = null;
    _connectedAt = null;
    _statusController.add('disconnected');
  }

  void dispose() {
    disconnect(reconnect: false);
    _statusController.close();
  }
}
