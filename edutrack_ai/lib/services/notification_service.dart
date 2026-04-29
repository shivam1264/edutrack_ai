import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/notification_model.dart';

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // IMPORTANT: Replace with your OneSignal IDs
  static const String oneSignalAppId = "d417e3e0-f416-4399-8f27-8180a8c566cc"; 
  static const String oneSignalRestKey = "os_v2_app_2ql6hyhuczbztdzhqgakrrlgzrfnmsos4xgu3numyimxuzqdop27f4nqavupckbtrifb2pqqhgegx5lfbx4jn56zbwrjxhqpfsb6hui";

  // ─── Initialize ───────────────────────────────────────────────────────────
  Future<void> initialize() async {
    // 1. OneSignal Initialization
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.initialize(oneSignalAppId);
    OneSignal.Notifications.requestPermission(true);

    // 2. Firebase Cloud Messaging (Legacy/Internal)
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // Handle messages when app is opened via OneSignal/FCM
    OneSignal.Notifications.addClickListener((event) {
      print("Notification Clicked: ${event.notification.body}");
    });
  }

  // ─── Topic/Tag Management ─────────────────────────────────────────────────
  Future<void> subscribeToClass(String classId) async {
    // Tag the user in OneSignal for targeted notifications
    final topic = 'class_${classId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
    OneSignal.User.addTagWithKey("class_topic", topic);
    
    // Also subscribe to FCM topic for redundancy
    await _fcm.subscribeToTopic(topic);
  }

  // ─── Send Notification (REST API - No Blaze Plan Required) ────────────────
  Future<void> sendClassNotification({
    required String classId,
    required String title,
    required String body,
    String type = 'general',
  }) async {
    final topic = 'class_${classId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
    
    try {
      final response = await http.post(
        Uri.parse('https://onesignal.com/api/v1/notifications'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Basic $oneSignalRestKey',
        },
        body: jsonEncode({
          'app_id': oneSignalAppId,
          'filters': [
            {"field": "tag", "key": "class_topic", "relation": "=", "value": topic}
          ],
          'headings': {'en': title},
          'contents': {'en': body},
          'data': {'type': type, 'class_id': classId},
        }),
      );

      if (response.statusCode == 200) {
        print("✅ OneSignal Notification Sent");
      } else {
        print("❌ OneSignal Error: ${response.body}");
      }
    } catch (e) {
      print("❌ Notification Error: $e");
    }
  }

  // ─── Send Global Notification ─────────────────────────────────────────────
  Future<void> sendGlobalNotification({
    required String title,
    required String body,
    String type = 'general',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://onesignal.com/api/v1/notifications'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Basic $oneSignalRestKey',
        },
        body: jsonEncode({
          'app_id': oneSignalAppId,
          'included_segments': ['All'],
          'headings': {'en': title},
          'contents': {'en': body},
          'data': {'type': type},
        }),
      );

      if (response.statusCode == 200) {
        print("✅ Global Notification Sent");
      } else {
        print("❌ OneSignal Error: ${response.body}");
      }
    } catch (e) {
      print("❌ Notification Error: $e");
    }
  }

  // ─── Save FCM token (Keeping for compatibility) ──────────────────────────
  Future<void> saveFcmToken(String userId) async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await _db.collection('users').doc(userId).update({
          'fcm_token': token,
          'fcm_updated': DateTime.now().toIso8601String(),
          'onesignal_id': OneSignal.User.pushSubscription.id,
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
    await _db.collection('notifications').doc(notificationId).update({'is_read': true});
  }

  // ─── Send internal notification (Firestore only) ──────────────────────────
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    String type = 'general',
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
