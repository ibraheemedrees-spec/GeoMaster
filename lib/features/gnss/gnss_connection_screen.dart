import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/services/gnss_service.dart';
import '../../core/theme/app_theme.dart';

class GnssConnectionScreen extends StatefulWidget {
  const GnssConnectionScreen({super.key});

  @override
  State<GnssConnectionScreen> createState() => _GnssConnectionScreenState();
}

class _GnssConnectionScreenState extends State<GnssConnectionScreen> {
  final GnssService _gnss = GnssService();
  List<ScanResult> _devices = [];
  bool _scanning = false;
  bool _connecting = false;
  String? _connectingId;
  StreamSubscription? _scanSub;
  StreamSubscription? _posSub;
  GnssPosition? _lastPos;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }

  Future<void> _startScan() async {
    setState(() {
      _scanning = true;
      _devices = [];
    });
    await _gnss.stopScan();
    _scanSub?.cancel();
    try {
      if (await FlutterBluePlus.isSupported == false) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('bluetooth_not_supported'.tr())),
          );
        }
        setState(() => _scanning = false);
        return;
      }
      await FlutterBluePlus.adapterState.where((s) => s == BluetoothAdapterState.on).first
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please turn on Bluetooth')),
        );
      }
      setState(() => _scanning = false);
      return;
    }

    _scanSub = _gnss.scanDevices().listen((results) {
      if (!mounted) return;
      setState(() {
        _devices = results.where((r) => r.device.platformName.isNotEmpty).toList()
          ..sort((a, b) => b.rssi.compareTo(a.rssi));
      });
    });

    Future.delayed(const Duration(seconds: 12), () {
      if (mounted && _scanning) _stopScan();
    });
  }

  void _stopScan() {
    _gnss.stopScan();
    _scanSub?.cancel();
    if (mounted) setState(() => _scanning = false);
  }

  Future<void> _connect(BluetoothDevice device) async {
    setState(() {
      _connecting = true;
      _connectingId = device.remoteId.str;
    });
    final ok = await _gnss.connect(device);
    if (ok) {
      _posSub?.cancel();
      _posSub = _gnss.positionStream.listen((pos) {
        if (mounted) setState(() => _lastPos = pos);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'connected_to'.tr()} ${device.platformName}'), backgroundColor: Colors.green),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('connection_failed'.tr()), backgroundColor: Colors.red),
      );
    }
    if (mounted) setState(() { _connecting = false; _connectingId = null; });
  }

  Future<void> _disconnect() async {
    await _gnss.disconnect();
    _posSub?.cancel();
    if (mounted) setState(() => _lastPos = null);
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _posSub?.cancel();
    _stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connected = _gnss.isConnected;
    return Scaffold(
      appBar: AppBar(title: Text('connect_gnss'.tr())),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: connected ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: connected ? Colors.green : Colors.grey.shade300),
            ),
            child: Column(
              children: [
                Icon(connected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                    size: 40, color: connected ? Colors.green : Colors.grey),
                const SizedBox(height: 8),
                Text(
                  connected ? '${'connected_to'.tr()}: ${_gnss.connectedDeviceName}' : 'not_connected'.tr(),
                  style: TextStyle(fontWeight: FontWeight.bold, color: connected ? Colors.green.shade700 : Colors.grey.shade700),
                ),
                if (_lastPos != null) ...[
                  const SizedBox(height: 8),
                  Text('Lat: ${_lastPos!.latitude.toStringAsFixed(8)}', style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
                  Text('Lng: ${_lastPos!.longitude.toStringAsFixed(8)}', style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
                  Text('Acc: ±${_lastPos!.accuracy.toStringAsFixed(2)} m | ${_lastPos!.quality.toUpperCase()}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: _lastPos!.quality.contains('rtk') ? Colors.green : Colors.orange)),
                ],
                if (connected) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _disconnect,
                    icon: const Icon(Icons.link_off, color: Colors.red),
                    label: Text('disconnect'.tr(), style: const TextStyle(color: Colors.red)),
                  ),
                ],
              ],
            ),
          ),
          if (!connected)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _scanning ? _stopScan : _startScan,
                  icon: _scanning
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.radar),
                  label: Text(_scanning ? 'stop_scan'.tr() : 'scan_devices'.tr()),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('available_devices'.tr(), style: TextStyle(color: Colors.grey.shade600)),
            ),
          ),
          Expanded(
            child: _devices.isEmpty
                ? Center(child: Text(_scanning ? 'scanning'.tr() : 'no_devices_found'.tr(), style: TextStyle(color: Colors.grey.shade500)))
                : ListView.builder(
                    itemCount: _devices.length,
                    itemBuilder: (context, i) {
                      final r = _devices[i];
                      final d = r.device;
                      final isThis = _connectingId == d.remoteId.str;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                          child: const Icon(Icons.gps_fixed, color: AppTheme.primaryColor),
                        ),
                        title: Text(d.platformName.isNotEmpty ? d.platformName : 'Unknown'),
                        subtitle: Text('RSSI: ${r.rssi} dBm'),
                        trailing: isThis
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                            : ElevatedButton(
                                onPressed: _connecting ? null : () => _connect(d),
                                child: Text('connect'.tr()),
                              ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
