import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/notification_model.dart';

/// Notification service using FCM only.
/// flutter_local_notifications removed (not needed for web/Chrome demo).
class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // ─── Initialize ───────────────────────────────────────────────────────────
  Future<void> initialize() async {
    // Request permission (iOS / web)
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Handle foreground FCM messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // In-app notification handling (no local notification popup needed)
      if (message.notification != null) {
        _saveToFirestore(
          userId: message.data['user_id'] ?? '',
          title: message.notification!.title ?? '',
          body: message.notification!.body ?? '',
          type: message.data['type'] ?? 'general',
          data: message.data,
        );
      }
    });
  }

  // ─── Save FCM token to Firestore ──────────────────────────────────────────
  Future<void> saveFcmToken(String userId) async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await _db.collection('users').doc(userId).update({
          'fcm_token': token,
          'fcm_updated': DateTime.now().toIso8601String(),
        });
      }
    } catch (_) {}
  }

  // ─── Notifications stream ─────────────────────────────────────────────────
  Stream<List<NotificationModel>> notificationsStream(String userId) {
    return _db
        .collection('notifications')
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => NotificationModel.fromMap(d.id, d.data()))
            .toList());
  }

  // ─── Unread count ─────────────────────────────────────────────────────────
  Stream<int> unreadCountStream(String userId) {
    return _db
        .collection('notifications')
        .where('user_id', isEqualTo: userId)
        .where('is_read', isEqualTo: false)
        .snapshots()
        .map((s) => s.docs.length);
  }

  // ─── Mark as read ─────────────────────────────────────────────────────────
  Future<void> markAsRead(String notificationId) async {
    await _db
        .collection('notifications')
        .doc(notificationId)
        .update({'is_read': true});
  }

  Future<void> markAllAsRead(String userId) async {
    final batch = _db.batch();
    final snap = await _db
        .collection('notifications')
        .where('user_id', isEqualTo: userId)
        .where('is_read', isEqualTo: false)
        .get();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'is_read': true});
    }
    await batch.commit();
  }

  // ─── Send notification (saves to Firestore) ───────────────────────────────
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    String type = 'general',
    Map<String, dynamic>? data,
  }) async {
    await _saveToFirestore(
      userId: userId,
      title: title,
      body: body,
      type: type,
      data: data,
    );
  }

  Future<void> _saveToFirestore({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    await _db.collection('notifications').add({
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type,
      'is_read': false,
      'data': data ?? {},
      'created_at': DateTime.now(),
    });
  }
}
