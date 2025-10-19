import 'package:flutter/foundation.dart';

@immutable
class Message {
  final int id;
  final String senderId;
  final String message;
  final DateTime createdAt;
  final bool isRead; 

  const Message({
    required this.id,
    required this.senderId,
    required this.message,
    required this.createdAt,
    required this.isRead,
  });

  /// Supabase'dan keladigan Map<String, dynamic> dan ob'ekt hosil qilish
  factory Message.fromMap(Map<String, dynamic> map) {
    // 1. ID ni parse qilish
    final parsedId = (map['id'] is int ? map['id'] as int : int.tryParse(map['id'].toString())) ?? 0;

    // 2. Sender va Message matnlarini olish.
    final sender = map['sender_id'] ?? map['senderId'] ?? '';
    
    final messageText = map['message'] ?? map['body'] ?? '';

    // 3. Yaratilgan vaqtni (DateTime) parse qilish.
    final createdRaw = map['created_at'] ?? map['createdAt'];
    DateTime parsedCreatedAt;
    
    if (createdRaw is String) {
      parsedCreatedAt = DateTime.tryParse(createdRaw) ?? DateTime.now();
    } else if (createdRaw is DateTime) {
      parsedCreatedAt = createdRaw;
    } else {
      parsedCreatedAt = DateTime.now();
    }

    // 4. O'qilganlik holatini olish.
    final isReadStatus = map['is_read'] ?? map['isRead'] ?? false;

    return Message(
      id: parsedId,
      senderId: sender.toString(),
      message: messageText.toString(),
      createdAt: parsedCreatedAt,
      isRead: isReadStatus as bool,
    );
  }

  /// (Optional) JSON map — alias to fromMap
  factory Message.fromJson(Map<String, dynamic> json) => Message.fromMap(json);

  /// To Map (agar kerak bo'lsa)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender_id': senderId,
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
    };
  }
  
  @override
  String toString() {
    return 'Message(id: $id, senderId: $senderId, message: $message, createdAt: $createdAt, isRead: $isRead)';
  }
}