import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message.dart';

class ChatService {
  final SupabaseClient _client = Supabase.instance.client;

  // Xabar yuborish (insert)
  Future<void> sendMessage(String senderId, String text) async {
    await _client.from('messages').insert({
      'sender_id': senderId,
      'message': text,
    });
  }

  // Realtime xabarlarni olish (stream)
  Stream<List<Message>> getMessagesStream() {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map((data) => data
            .map((row) => Message.fromMap(row as Map<String, dynamic>))
            .toList());
  }
}
