import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool isMe;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    required this.isMe,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc, String currentUserId) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      senderId: data['sender_id'] ?? '',
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isMe: data['sender_id'] == currentUserId,
    );
  }
}

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<ChatMessage>> streamMessages(String chatId, String currentUserId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => ChatMessage.fromFirestore(doc, currentUserId)).toList());
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
    String? studentId,
    String? teacherId,
    String? senderName, // Added to show in notification
  }) async {
    await _db.collection('chats').doc(chatId).collection('messages').add({
      'sender_id': senderId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });
    
    final Map<String, dynamic> chatUpdate = {
      'last_message': text,
      'last_timestamp': FieldValue.serverTimestamp(),
      'last_sender_id': senderId,
    };

    if (studentId != null) chatUpdate['student_id'] = studentId;
    if (teacherId != null) chatUpdate['teacher_id'] = teacherId;

    await _db.collection('chats').doc(chatId).set(chatUpdate, SetOptions(merge: true));

    // Send Push Notification
    try {
      final targetId = (senderId == teacherId) ? studentId : teacherId;
      if (targetId != null) {
        await NotificationService.instance.sendNotification(
          userId: targetId,
          title: 'New Message from ${senderName ?? "Chat"}',
          body: text,
        );
      }
    } catch (e) {
      print('Error sending chat notification: $e');
    }
  }
}
