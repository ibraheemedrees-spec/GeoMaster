import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../core/services/gnss_service.dart';
import '../../core/theme/app_theme.dart';

class GnssConnectionScreen extends StatefulWidget {
  const GnssConnectionScreen({super.key});

  @override
  State<GnssConnectionScreen> createState() => _GnssConnectionScreenState();
}

class _GnssConnectionScreenState extends State<GnssConnectionScreen> {
  final GnssService _gnssService = GnssService();
  List<ScanResult> _devices = [];
  bool _isScanning = false;
  bool _isConnecting = false;
  String? _connectingId;
  StreamSubscription? _scanSub;
  StreamSubscription? _positionSub;
  GnssPosition? _lastPosition;

  @override
  void initState() {
    super.initState();
    _checkBluetooth();
  }

  Future<void> _checkBluetooth() async {
    if (await FlutterBluePlus.isSupported == false) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('bluetooth_not_supported'.tr())),
        );
      }
      return;
    }

    // Listen to adapter state
    FlutterBluePlus.adapterState.listen((state) {
      if (state == BluetoothAdapterState.on) {
        // ready
      }
    });
  }

  void _startScan() async {
    setState(() {
      _isScanning = true;
      _devices = [];
    });

    await _gnssService.stopScan();
    _scanSub?.cancel();

    _scanSub = _gnssService.scanDevices().listen((results) {
      setState(() {
        // Filter devices that have a name (likely real devices)
        _devices = results
            .where((r) => r.device.platformName.isNotEmpty)
            .toList()
          ..sort((a, b) => b.rssi.compareTo(a.rssi));
      });
    });

    // Auto stop after 12 seconds
    Future.delayed(const Duration(seconds: 12), () {
      if (mounted && _isScanning) {
        _stopScan();
      }
    });
  }

  void _stopScan() {
    _gnssService.stopScan();
    _scanSub?.cancel();
    setState(() => _isScanning = false);
  }

  Future<void> _connect(BluetoothDevice device) async {
    setState(() {
      _isConnecting = true;
      _connectingId = device.remoteId.str;
    });

    final success = await _gnssService.connect(device);

    if (success) {
      // Listen to positions
      _positionSub?.cancel();
      _positionSub = _gnssService.positionStream.listen((pos) {
        setState(() => _lastPosition = pos);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'connected_to'.tr()} ${device.platformName}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('connection_failed'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() {
      _isConnecting = false;
      _connectingId = null;
    });
  }

  Future<void> _disconnect() async {
    await _gnssService.disconnect();
    _positionSub?.cancel();
    setState(() => _lastPosition = null);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('disconnected'.tr())),
      );
    }
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _positionSub?.cancel();
    _stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = _gnssService.isConnected;

    return Scaffold(
      appBar: AppBar(
        title: Text('connect_gnss'.tr()),
      ),
      body: Column(
        children: [
          // Status card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isConnected
                  ? Colors.green.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isConnected ? Colors.green : Colors.grey.shade300,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                  size: 40,
                  color: isConnected ? Colors.green : Colors.grey,
                ),
                const SizedBox(height: 8),
                Text(
                  isConnected
                      ? '${'connected_to'.tr()}: ${_gnssService.connectedDeviceName}'
                      : 'not_connected'.tr(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isConnected ? Colors.green.shade700 : Colors.grey.shade700,
                  ),
                ),
                if (_lastPosition != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Lat: ${_lastPosition!.latitude.toStringAsFixed(8)}',
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  ),
                  Text(
                    'Lng: ${_lastPosition!.longitude.toStringAsFixed(8)}',
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  ),
                  Text(
                    'Acc: ±${_lastPosition!.accuracy.toStringAsFixed(2)} m  |  ${_lastPosition!.quality.toUpperCase()}',
                    style: TextStyle(
                      fontSize: 13,
                      color: _lastPosition!.quality.contains('rtk')
                          ? Colors.green
                          : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_lastPosition!.satellites != null)
                    Text(
                      'Sats: ${_lastPosition!.satellites}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
                if (isConnected) ...[
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

          // Scan button
          if (!isConnected)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isScanning ? _stopScan : _startScan,
                  icon: _isScanning
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.radar),
                  label: Text(_isScanning ? 'stop_scan'.tr() : 'scan_devices'.tr()),
                ),
              ),
            ),

          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'available_devices'.tr(),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Devices list
          Expanded(
            child: _devices.isEmpty
                ? Center(
                    child: Text(
                      _isScanning ? 'scanning'.tr() : 'no_devices_found'.tr(),
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  )
                : ListView.builder(
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      final result = _devices[index];
                      final device = result.device;
                      final isThisConnecting = _connectingId == device.remoteId.str;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                          child: const Icon(Icons.gps_fixed, color: AppTheme.primaryColor),
                        ),
                        title: Text(
                          device.platformName.isNotEmpty
                              ? device.platformName
                              : 'Unknown Device',
                        ),
                        subtitle: Text('RSSI: ${result.rssi} dBm'),
                        trailing: isThisConnecting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : ElevatedButton(
                                onPressed: _isConnecting ? null : () => _connect(device),
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
