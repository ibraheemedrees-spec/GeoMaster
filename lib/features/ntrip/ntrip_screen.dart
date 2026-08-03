import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/services/ntrip_service.dart';

class NtripScreen extends StatefulWidget {
  const NtripScreen({super.key});

  @override
  State<NtripScreen> createState() => _NtripScreenState();
}

class _NtripScreenState extends State<NtripScreen> {
  final _hostController = TextEditingController(text: 'caster.centipede.fr');
  final _portController = TextEditingController(text: '2101');
  final _mountController = TextEditingController();
  final _userController = TextEditingController();
  final _passController = TextEditingController();

  final NtripService _ntrip = NtripService();
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _connect() async {
    if (_mountController.text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('required_field'.tr())),
      );
      return;
    }

    setState(() => _isConnecting = true);

    final ok = await _ntrip.connect(
      host: _hostController.text.trim(),
      port: int.tryParse(_portController.text) ?? 2101,
      mountpoint: _mountController.text.trim(),
      username: _userController.text.trim(),
      password: _passController.text,
    );

    if (!mounted) return;
    setState(() => _isConnecting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'ntrip_connected'.tr() : 'ntrip_failed'.tr()),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _disconnect() async {
    await _ntrip.disconnect();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _mountController.dispose();
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connected = _ntrip.isConnected;

    return Scaffold(
      appBar: AppBar(title: Text('ntrip_settings'.tr())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: connected ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: connected ? Colors.green : Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(
                    connected ? Icons.cloud_done : Icons.cloud_off,
                    color: connected ? Colors.green : Colors.grey,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          connected ? 'ntrip_connected'.tr() : 'ntrip_disconnected'.tr(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: connected ? Colors.green.shade700 : Colors.grey.shade700,
                          ),
                        ),
                        if (connected && _ntrip.mountpoint != null)
                          Text('${_ntrip.caster} / ${_ntrip.mountpoint}', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _hostController,
              decoration: InputDecoration(
                labelText: 'ntrip_host'.tr(),
                prefixIcon: const Icon(Icons.dns),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _portController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'ntrip_port'.tr(),
                prefixIcon: const Icon(Icons.numbers),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _mountController,
              decoration: InputDecoration(
                labelText: 'ntrip_mountpoint'.tr(),
                prefixIcon: const Icon(Icons.stream),
                hintText: 'e.g. MOUNT1',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _userController,
              decoration: InputDecoration(
                labelText: 'username'.tr(),
                prefixIcon: const Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'password'.tr(),
                prefixIcon: const Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 24),
            if (!connected)
              ElevatedButton.icon(
                onPressed: _isConnecting ? null : _connect,
                icon: _isConnecting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.cloud_upload),
                label: Text('connect'.tr()),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              )
            else
              OutlinedButton.icon(
                onPressed: _disconnect,
                icon: const Icon(Icons.cloud_off, color: Colors.red),
                label: Text('disconnect'.tr(), style: const TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            const SizedBox(height: 16),
            Text(
              'ntrip_note'.tr(),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
