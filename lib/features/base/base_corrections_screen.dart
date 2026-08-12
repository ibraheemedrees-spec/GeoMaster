import 'package:flutter/material.dart';
import '../../core/survey/base_session.dart';

class BaseCorrectionsScreen extends StatefulWidget {
  const BaseCorrectionsScreen({super.key});
  @override
  State<BaseCorrectionsScreen> createState() => _BaseCorrectionsScreenState();
}

class _BaseCorrectionsScreenState extends State<BaseCorrectionsScreen> {
  final base = BaseSession.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Base Corrections')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Correction formats enabled only when supported by the connected receiver. Proprietary formats require OEM adapter.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
          const ListTile(title: Text('Format'), dense: true),
          RadioListTile<String>(
            title: const Text('RTCM 3.x'),
            subtitle: const Text('Standard — preferred'),
            value: 'rtcm3',
            groupValue: base.correctionFormat,
            onChanged: (v) => setState(() => base.correctionFormat = v!),
          ),
          RadioListTile<String>(
            title: const Text('RTCM 2.x'),
            subtitle: const Text('Legacy — if receiver supports'),
            value: 'rtcm2',
            groupValue: base.correctionFormat,
            onChanged: (v) => setState(() => base.correctionFormat = v!),
          ),
          RadioListTile<String>(
            title: const Text('CMR / CMR+'),
            subtitle: const Text('Requires OEM support — not assumed'),
            value: 'cmr',
            groupValue: base.correctionFormat,
            onChanged: (v) => setState(() => base.correctionFormat = v!),
          ),
          const Divider(),
          const ListTile(title: Text('Output transport'), dense: true),
          ...['radio', 'network', 'serial', 'bluetooth', 'tcp', 'none'].map((o) {
            return RadioListTile<String>(
              title: Text(o.toUpperCase()),
              value: o,
              groupValue: base.correctionOutput,
              onChanged: (v) => setState(() => base.correctionOutput = v!),
            );
          }),
        ],
      ),
    );
  }
}
