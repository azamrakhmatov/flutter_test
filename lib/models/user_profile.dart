import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfile {
  final String id;
  final String username;
  final String? avatarUrl;
  final String? email;

  UserProfile({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.email
  });

  /// Supabase Auth yoki 'profiles' jadvalidan kelgan ma'lumotlarni o'zgartirish
  factory UserProfile.fromMap(Map<String, dynamic> map, String? email) {
    return UserProfile(
      id: map['id'] as String,
      username: map['username'] as String? ?? 'Unknown User',
      avatarUrl: map['avatar_url'] as String?,
      email: email
    );
  }

  /// Supabase 'User' ob'ektidan asosiy ma'lumotlarni olish (ko'pincha id)
  factory UserProfile.fromAuthUser(User user) {
    return UserProfile(
      id: user.id,
      // Supabase Auth orqali birinchi marta kirganda username yo'q, shuning uchun 'temp' beramiz
      username: user.email ?? 'temp_user', 
      avatarUrl: null,
      email: user.email
    );
  }
}
