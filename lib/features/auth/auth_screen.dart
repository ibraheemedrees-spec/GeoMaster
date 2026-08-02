import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/services/cloud_sync_service.dart';
import '../../core/theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _cloud = CloudSyncService();
  bool _isLogin = true;
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    final err = _isLogin
        ? await _cloud.signIn(_emailCtrl.text.trim(), _passCtrl.text)
        : await _cloud.signUp(_emailCtrl.text.trim(), _passCtrl.text);
    setState(() { _loading = false; _error = err; });
    if (err == null && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'login'.tr() : 'register'.tr())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.cloud_sync, size: 64, color: AppTheme.primaryColor),
            const SizedBox(height: 16),
            Text(
              'cloud_sync_desc'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: 'email'.tr(), prefixIcon: const Icon(Icons.email)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passCtrl,
              obscureText: true,
              decoration: InputDecoration(labelText: 'password'.tr(), prefixIcon: const Icon(Icons.lock)),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              child: _loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_isLogin ? 'login'.tr() : 'register'.tr()),
            ),
            TextButton(
              onPressed: () => setState(() => _isLogin = !_isLogin),
              child: Text(_isLogin ? 'create_account'.tr() : 'have_account'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
