import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/services/gnss_service.dart';
import '../../core/theme/app_theme.dart';

class SatellitesScreen extends StatefulWidget {
  const SatellitesScreen({super.key});

  @override
  State<SatellitesScreen> createState() => _SatellitesScreenState();
}

class _SatellitesScreenState extends State<SatellitesScreen> {
  final GnssService _gnss = GnssService();
  StreamSubscription? _satsSub;
  StreamSubscription<Position>? _posSub;
  List<SatelliteInfo> _sats = [];
  Position? _phonePos;
  int? _ggaCount;

  @override
  void initState() {
    super.initState();
    _sats = List.from(_gnss.currentSatellites);
    _satsSub = _gnss.satellitesStream.listen((list) {
      if (mounted) setState(() => _sats = list);
    });
    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
    ).listen((p) {
      if (mounted) setState(() => _phonePos = p);
    });
    _gnss.positionStream.listen((p) {
      if (mounted) setState(() => _ggaCount = p.satellites);
    });
  }

  @override
  void dispose() {
    _satsSub?.cancel();
    _posSub?.cancel();
    super.dispose();
  }

  Map<String, List<SatelliteInfo>> get _byConstellation {
    final map = <String, List<SatelliteInfo>>{};
    for (final s in _sats) {
      map.putIfAbsent(s.constellation, () => []).add(s);
    }
    for (final list in map.values) {
      list.sort((a, b) => b.snr.compareTo(a.snr));
    }
    return map;
  }

  Color _snrColor(int snr) {
    if (snr >= 40) return Colors.green;
    if (snr >= 30) return Colors.lightGreen;
    if (snr >= 20) return Colors.orange;
    if (snr > 0) return Colors.redAccent;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final by = _byConstellation;
    final used = _sats.where((s) => s.snr > 0).length;

    return Scaffold(
      appBar: AppBar(title: Text('satellites'.tr())),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary card
          Card(
            color: Colors.black87,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _stat('${_sats.length}', 'total_sats'.tr()),
                      _stat('$used', 'with_signal'.tr()),
                      _stat(
                        _ggaCount?.toString() ?? (_phonePos != null ? 'GPS' : '—'),
                        'in_fix'.tr(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_gnss.isConnected)
                    Text(
                      '${'connected_to'.tr()}: ${_gnss.connectedDeviceName}',
                      style: const TextStyle(color: Colors.greenAccent, fontSize: 12),
                    )
                  else
                    Text(
                      'satellites_phone_note'.tr(),
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  if (_phonePos != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Phone GPS ±${_phonePos!.accuracy.toStringAsFixed(1)} m',
                      style: const TextStyle(color: Colors.lightBlueAccent, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Simple sky plot
          if (_sats.isNotEmpty) ...[
            Text('sky_plot'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: CustomPaint(
                painter: _SkyPlotPainter(_sats),
                child: Container(),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // By constellation
          if (_sats.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.satellite_alt, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    _gnss.isConnected
                        ? 'waiting_satellite_data'.tr()
                        : 'connect_gnss_for_sats'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          else
            ...by.entries.map((e) {
              return Card(
                child: ExpansionTile(
                  initiallyExpanded: true,
                  leading: Icon(_iconFor(e.key), color: AppTheme.primaryColor),
                  title: Text('${e.key} (${e.value.length})'),
                  children: e.value.map((s) {
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: _snrColor(s.snr).withOpacity(0.2),
                        child: Text('${s.prn}', style: TextStyle(fontSize: 11, color: _snrColor(s.snr), fontWeight: FontWeight.bold)),
                      ),
                      title: Text('PRN ${s.prn}'),
                      subtitle: Text('Elev ${s.elevation}°  Az ${s.azimuth}°'),
                      trailing: Text(
                        s.snr > 0 ? '${s.snr} dBHz' : '—',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _snrColor(s.snr),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
      ],
    );
  }

  IconData _iconFor(String c) {
    switch (c) {
      case 'GPS':
        return Icons.gps_fixed;
      case 'GLONASS':
        return Icons.public;
      case 'Galileo':
        return Icons.euro;
      case 'BeiDou':
        return Icons.brightness_1;
      default:
        return Icons.satellite_alt;
    }
  }
}

class _SkyPlotPainter extends CustomPainter {
  final List<SatelliteInfo> sats;
  _SkyPlotPainter(this.sats);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;

    final bg = Paint()..color = Colors.grey.shade200;
    canvas.drawCircle(center, radius, bg);

    final ring = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, radius, ring);
    canvas.drawCircle(center, radius * 0.66, ring);
    canvas.drawCircle(center, radius * 0.33, ring);

    // Cross
    canvas.drawLine(Offset(center.dx - radius, center.dy), Offset(center.dx + radius, center.dy), ring);
    canvas.drawLine(Offset(center.dx, center.dy - radius), Offset(center.dx, center.dy + radius), ring);

    // N label
    final tp = TextPainter(
      text: const TextSpan(text: 'N', style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - radius - 2));

    for (final s in sats) {
      if (s.elevation <= 0 && s.snr <= 0) continue;
      // elevation 90 = center, 0 = edge
      final r = radius * (1 - s.elevation.clamp(0, 90) / 90.0);
      final azRad = (s.azimuth - 90) * math.pi / 180; // 0=N → adjust
      // standard: azimuth 0 = North, clockwise
      final x = center.dx + r * math.sin(s.azimuth * math.pi / 180);
      final y = center.dy - r * math.cos(s.azimuth * math.pi / 180);

      Color color = Colors.grey;
      if (s.constellation == 'GPS') color = Colors.blue;
      if (s.constellation == 'GLONASS') color = Colors.red;
      if (s.constellation == 'Galileo') color = Colors.amber.shade700;
      if (s.constellation == 'BeiDou') color = Colors.green;

      final paint = Paint()..color = color.withOpacity(s.snr > 0 ? 1 : 0.3);
      canvas.drawCircle(Offset(x, y), s.snr > 30 ? 7 : 5, paint);

      final label = TextPainter(
        text: TextSpan(text: '${s.prn}', style: const TextStyle(fontSize: 8, color: Colors.black87)),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(canvas, Offset(x - label.width / 2, y + 6));
    }
  }

  @override
  bool shouldRepaint(covariant _SkyPlotPainter old) => true;
}
