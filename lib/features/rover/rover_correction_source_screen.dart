import 'package:flutter/material.dart';
import '../../core/survey/rover_session.dart';
import '../ntrip/ntrip_screen.dart';

class RoverCorrectionSourceScreen extends StatefulWidget {
  const RoverCorrectionSourceScreen({super.key});
  @override
  State<RoverCorrectionSourceScreen> createState() => _RoverCorrectionSourceScreenState();
}

class _RoverCorrectionSourceScreenState extends State<RoverCorrectionSourceScreen> {
  final rover = RoverSession.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Correction Source')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Select how the external rover receiver obtains RTK corrections.'),
          ),
          ...[
            ('ntrip', 'NTRIP', 'Internet caster → controller can relay / monitor'),
            ('radio', 'Radio', 'UHF/VHF from base radio — requires receiver radio'),
            ('tcp', 'TCP/IP', 'Network stream to receiver or controller'),
            ('serial', 'Serial', 'Direct serial correction input'),
            ('bluetooth', 'Bluetooth', 'Correction over BT (if supported)'),
            ('none', 'None', 'Standalone GNSS — no RTK corrections'),
          ].map((e) {
            return RadioListTile<String>(
              title: Text(e.$2),
              subtitle: Text(e.$3),
              value: e.$1,
              groupValue: rover.correctionSource,
              onChanged: (v) => setState(() => rover.correctionSource = v!),
            );
          }),
          if (rover.correctionSource == 'ntrip')
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text('Configure NTRIP'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NtripScreen())),
            ),
          if (rover.correctionSource == 'radio')
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Radio correction requires the external receiver\'s radio hardware. GeoMaster stores channel settings; it does not invent radio protocols.',
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}
