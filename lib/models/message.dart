class Message {
  final int id;
  final String senderId;
  final String message;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.senderId,
    required this.message,
    required this.createdAt,
  });

  /// Supabase'dan keladigan Map<String, dynamic> dan ob'ekt hosil qilish
  factory Message.fromMap(Map<String, dynamic> map) {
    // id may come as int or string (cast it safely)
    int parsedId;
    try {
      parsedId = map['id'] is int ? map['id'] as int : int.parse(map['id'].toString());
    } catch (_) {
      parsedId = 0;
    }

    // sender_id may be null — convert to empty string if so
    final sender = map['sender_id'] ?? map['senderId'] ?? '';
    final messageText = map['message'] ?? map['body'] ?? '';

    DateTime parsedCreatedAt;
    final createdRaw = map['created_at'] ?? map['createdAt'];
    if (createdRaw == null) {
      parsedCreatedAt = DateTime.now();
    } else if (createdRaw is DateTime) {
      parsedCreatedAt = createdRaw;
    } else {
      // try parse string
      parsedCreatedAt = DateTime.tryParse(createdRaw.toString()) ?? DateTime.now();
    }

    return Message(
      id: parsedId,
      senderId: sender.toString(),
      message: messageText.toString(),
      createdAt: parsedCreatedAt,
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
    };
  }
}
