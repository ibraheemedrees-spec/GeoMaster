import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/project_model.dart';

/// Cloud sync - safe when Firebase is not configured
class CloudSyncService {
  static final CloudSyncService _instance = CloudSyncService._internal();
  factory CloudSyncService() => _instance;
  CloudSyncService._internal();

  bool get isLoggedIn => false;
  dynamic get currentUser => null;

  Future<String?> signUp(String email, String password) async {
    return 'Firebase is not configured in this build';
  }

  Future<String?> signIn(String email, String password) async {
    return 'Firebase is not configured in this build';
  }

  Future<void> signOut() async {}

  Future<int> uploadProjects() async => 0;
  Future<int> downloadProjects() async => 0;

  Future<Map<String, int>> syncAll() async {
    return {'uploaded': 0, 'downloaded': 0};
  }
}
