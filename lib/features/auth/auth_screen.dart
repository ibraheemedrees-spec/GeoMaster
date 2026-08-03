import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('login'.tr())),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Cloud sync requires Firebase configuration.\nNot available in this build.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
