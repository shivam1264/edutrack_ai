import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum NotificationType {
  assignment,
  quiz,
  attendance,
  grade,
  announcement,
  general,
}

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final bool isRead;
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  final String? senderName;
  final String? senderId;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.isRead = false,
    this.data,
    required this.createdAt,
    this.senderName,
    this.senderId,
  });

  factory NotificationModel.fromMap(String id, Map<String, dynamic> map) {
    return NotificationModel(
      id: id,
      userId: map['user_id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == (map['type'] as String? ?? 'general'),
        orElse: () => NotificationType.general,
      ),
      isRead: map['is_read'] as bool? ?? false,
      data: map['data'] as Map<String, dynamic>?,
      createdAt: (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      senderName: map['sender_name'] as String?,
      senderId: map['sender_id'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type.name,
      'is_read': isRead,
      'data': data,
      'created_at': Timestamp.fromDate(createdAt),
      'sender_name': senderName,
      'sender_id': senderId,
    };
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      userId: userId,
      title: title,
      body: body,
      type: type,
      isRead: isRead ?? this.isRead,
      data: data,
      createdAt: createdAt,
      senderName: senderName,
      senderId: senderId,
    );
  }

  IconData get icon {
    switch (type) {
      case NotificationType.assignment:
        return Icons.assignment_rounded;
      case NotificationType.quiz:
        return Icons.quiz_rounded;
      case NotificationType.attendance:
        return Icons.how_to_reg_rounded;
      case NotificationType.grade:
        return Icons.grade_rounded;
      case NotificationType.announcement:
        return Icons.campaign_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }
}
