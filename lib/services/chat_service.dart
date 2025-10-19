import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message.dart';

class ChatService {
  final SupabaseClient client = Supabase.instance.client;

  // Xabar yuborish
  Future<void> sendMessage(String senderId, String message) async {
    await client.from('messages').insert({
      'sender_id': senderId,
      'message': message,
      'is_read': false, // YANGI: Yuborilganda 'false' bo'ladi
    });
  }

  // YANGI: Xabarni o'qilgan deb belgilash
  Future<void> markMessageAsRead(int messageId) async {
    await client
        .from('messages')
        .update({'is_read': true})
        .eq('id', messageId);
  }

  // Realtime stream (UI uchun)
  Stream<List<Message>> getMessagesStream() {
    return client
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at') // eski -> yangi tartib
        .map((data) => data.map((row) => Message.fromMap(row)).toList());
  }
}
