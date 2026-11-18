import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static User? get currentUser => _auth.currentUser;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // สมัครสมาชิกใหม่ พร้อมสร้างข้อมูลโปรไฟล์ใน Firestore
  static Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    await cred.user?.updateDisplayName(name.trim());
    if (cred.user != null) {
      await _db.collection('users').doc(cred.user!.uid).set({
        'name': name.trim(),
        'email': email.trim(),
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // เข้าสู่ระบบ
  static Future<void> login({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  // ออกจากระบบ
  static Future<void> logout() async {
    await _auth.signOut();
  }

  // ดึงข้อมูลโปรไฟล์และ Role ของผู้ใช้ปัจจุบัน
  static Future<dynamic> getUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _db.collection('users').doc(user.uid).get();
    if (doc.exists) {
      return doc.data();
    }
    return {
      'name': user.displayName ?? 'สมาชิก kinkin',
      'email': user.email ?? '',
      'role': 'user',
    };
  }

  // โหลดรายการร้านโปรดของผู้ใช้จาก Firestore
  static Future<dynamic> loadFavorites() async {
    final user = _auth.currentUser;
    if (user == null) return <String, Restaurant>{};
    final snapshot = await _db
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .get();
    final result = <String, Restaurant>{};
    for (final doc in snapshot.docs) {
      try {
        result[doc.id] = Restaurant.fromJson(doc.data());
      } catch (_) {}
    }
    return result;
  }

  // บันทึกหรือลบร้านโปรดใน Firestore
  static Future<void> toggleFavorite(Restaurant r, bool isNowFavorite) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final ref = _db
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(r.id);
    if (isNowFavorite) {
      await ref.set(r.toJson());
    } else {
      await ref.delete();
    }
  }

  // บันทึก Log พฤติกรรมการใช้งานลง Collection กลาง
  static Future<void> logActivity({
    required String action,
    required Restaurant restaurant,
  }) async {
    try {
      await _db.collection('activity_logs').add({
        'userId': _auth.currentUser?.uid ?? 'guest',
        'userEmail': _auth.currentUser?.email ?? 'Guest User',
        'action': action,
        'restaurantId': restaurant.id,
        'restaurantName': restaurant.name,
        'isPartner': restaurant.isPartner,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  // ดึงสถิติรวมทั้งระบบสำหรับหน้า Admin Dashboard
  static Future<dynamic> getAdminSystemStats() async {
    final usersSnap = await _db.collection('users').get();
    final logsSnap = await _db
        .collection('activity_logs')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .get();

    int totalRolls = 0;
    int totalDirections = 0;
    for (final doc in logsSnap.docs) {
      final action = doc.data()['action'];
      if (action == 'roll') totalRolls++;
      if (action == 'directions') totalDirections++;
    }

    return {
      'totalUsers': usersSnap.docs.length,
      'usersList': usersSnap.docs.map((d) => d.data()).toList(),
      'totalRolls': totalRolls,
      'totalDirections': totalDirections,
      'recentLogs': logsSnap.docs.map((d) => d.data()).toList(),
    };
  }
}