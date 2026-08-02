import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/project_model.dart';

class CloudSyncService {
  static final CloudSyncService _instance = CloudSyncService._internal();
  factory CloudSyncService() => _instance;
  CloudSyncService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  Future<String?> signUp(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Upload all local projects to Firestore
  Future<int> uploadProjects() async {
    if (!isLoggedIn) return 0;
    final box = Hive.box<ProjectModel>('projects');
    final uid = currentUser!.uid;
    int count = 0;

    for (var project in box.values) {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('projects')
          .doc(project.id)
          .set(project.toMap());
      count++;
    }
    return count;
  }

  /// Download projects from Firestore and merge with local
  Future<int> downloadProjects() async {
    if (!isLoggedIn) return 0;
    final box = Hive.box<ProjectModel>('projects');
    final uid = currentUser!.uid;
    final snap = await _firestore.collection('users').doc(uid).collection('projects').get();
    int count = 0;

    for (var doc in snap.docs) {
      try {
        final project = ProjectModel.fromMap(doc.data());
        await box.put(project.id, project);
        count++;
      } catch (_) {}
    }
    return count;
  }

  /// Sync both ways (upload then download)
  Future<Map<String, int>> syncAll() async {
    final up = await uploadProjects();
    final down = await downloadProjects();
    return {'uploaded': up, 'downloaded': down};
  }
}
