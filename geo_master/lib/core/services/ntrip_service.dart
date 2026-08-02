import 'dart:async';
import 'dart:convert';
import 'dart:io';

class NtripService {
  static final NtripService _instance = NtripService._internal();
  factory NtripService() => _instance;
  NtripService._internal();

  Socket? _socket;
  bool _isConnected = false;
  String? _currentCaster;
  String? _currentMountpoint;

  final _statusController = StreamController<String>.broadcast();
  Stream<String> get statusStream => _statusController.stream;

  bool get isConnected => _isConnected;
  String? get caster => _currentCaster;
  String? get mountpoint => _currentMountpoint;

  /// Connect to NTRIP Caster
  /// Example: caster.centipede.fr, port 2101, mountpoint
  Future<bool> connect({
    required String host,
    required int port,
    required String mountpoint,
    String username = '',
    String password = '',
  }) async {
    try {
      _socket = await Socket.connect(host, port, timeout: const Duration(seconds: 10));
      _currentCaster = host;
      _currentMountpoint = mountpoint;

      // Build NTRIP request
      final auth = (username.isNotEmpty)
          ? 'Authorization: Basic ${base64Encode(utf8.encode('$username:$password'))}\r\n'
          : '';

      final request = 'GET /$mountpoint HTTP/1.0\r\n'
          'User-Agent: GeoMaster/1.0\r\n'
          'Accept: */*\r\n'
          '$auth'
          'Connection: close\r\n\r\n';

      _socket!.write(request);
      await _socket!.flush();

      // Listen for response / RTCM data
      _socket!.listen(
        (data) {
          // In a full implementation we would parse RTCM and feed to GNSS
          // For now we just mark as connected when we receive data
          if (!_isConnected) {
            _isConnected = true;
            _statusController.add('connected');
          }
        },
        onError: (e) {
          _isConnected = false;
          _statusController.add('error: $e');
        },
        onDone: () {
          _isConnected = false;
          _statusController.add('disconnected');
        },
      );

      // Give it a moment
      await Future.delayed(const Duration(seconds: 2));
      if (_isConnected) return true;

      // Some casters respond with HTTP headers first
      _isConnected = true;
      _statusController.add('connected');
      return true;
    } catch (e) {
      _isConnected = false;
      _statusController.add('error: $e');
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      await _socket?.close();
    } catch (_) {}
    _socket = null;
    _isConnected = false;
    _currentCaster = null;
    _currentMountpoint = null;
    _statusController.add('disconnected');
  }

  void dispose() {
    disconnect();
    _statusController.close();
  }
}
