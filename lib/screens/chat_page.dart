import 'dart:async';
import 'package:exam/models/message.dart';
import 'package:exam/models/user_profile.dart'; 
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

// Mobil ilova uchun yangi importlar
import 'dart:typed_data'; 
import 'dart:io'; 
import 'package:image_picker/image_picker.dart'; // Rasm tanlash uchun
import 'package:path/path.dart' as path; // Fayl nomini olish uchun

// Supabase client instance
final supabase = Supabase.instance.client;

class ChatPage extends StatefulWidget { 
  final String userId;
  const ChatPage({super.key, required this.userId});

  @override
  State<ChatPage> createState() => _ChatPageState();
} 

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  
  // UserID => UserProfile xaritasi
  Map<String, UserProfile> _userProfiles = {}; 
  // Hozirda yuklanayotgan ID'lar to'plami
  Set<String> _loadingUserIds = {}; 
  
  // Joriy foydalanuvchining to'liq profil ma'lumotlari future
  late Future<UserProfile> _myProfileFuture;
  
  // Profilni tahrirlash uchun Controller
  late final TextEditingController _usernameController;

  @override
  void initState() {
    super.initState();
    // Boshlang'ich profilni yuklashni boshlash
    _myProfileFuture = _loadMyProfile();
    _usernameController = TextEditingController();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  // Supabase orqali xabar yuborish
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final messageText = _messageController.text.trim();
    _messageController.clear();
    
    try {
      // is_read ni false qilib yuboramiz
      await supabase.from('messages').insert({
        'sender_id': widget.userId,
        'message': messageText,
        'is_read': false, 
      });
      _scrollToBottom();
    } catch (e) {
      _showErrorSnackbar("메시지 전송 중 오류가 발생했습니다: $e");
    }
  }

  // Ekranni eng pastga surish
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        Future.delayed(const Duration(milliseconds: 50), () {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      }
    });
  }
  
  // Chiqish (Logout) funksiyasi
  Future<void> _logout() async {
    try {
      await supabase.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/',
          (route) => false,
        );
      }
    } catch (e) {
      _showErrorSnackbar("로그아웃 중 오류가 발생했습니다.: $e");
    }
  }

  // Xato xabarlarini ko'rsatish
  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  // --- PROFIL FUNKSIYALARI ---

  // Joriy foydalanuvchining to'liq profilini yuklash
  Future<UserProfile> _loadMyProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception("로그인되지 않은 사용자입니다.");
    }
    
    try {
      final response = await supabase
          .from('profiles')
          .select('*')
          .eq('id', widget.userId)
          .single();
      
      return UserProfile.fromMap(response, user.email); 
    } catch (e) {
      // Agar 'profiles' jadvalida profil hali mavjud bo'lmasa
      return UserProfile.fromAuthUser(user);
    }
  }

  // Barcha xabarlardagi profillarni keshga yuklashni boshlash
  void _checkAndLoadUserProfiles(List<Message> messages) {
    final Set<String> neededIds = messages
        .map((m) => m.senderId)
        .where((id) => !_userProfiles.containsKey(id) && !_loadingUserIds.contains(id))
        .toSet();

    if (neededIds.isEmpty) return;

    _loadingUserIds.addAll(neededIds);

    _loadUserProfiles(neededIds).then((loadedProfiles) {
      if (mounted) {
        setState(() {
          _userProfiles.addAll(loadedProfiles);
        });
      }
    }).whenComplete(() {
      _loadingUserIds.removeAll(neededIds); 
    });
  }

  // Haqiqiy profil yuklash funksiyasi
  Future<Map<String, UserProfile>> _loadUserProfiles(Set<String> uniqueUserIds) async {
    final Map<String, UserProfile> loadedProfiles = {};
    final List<String> idsToFetch = uniqueUserIds.toList();

    try {
      // Supabase'dan ma'lumotlarni yuklash (RLS tufayli endi ishlashi kerak)
      final List<Map<String, dynamic>> response = await supabase
          .from('profiles')
          .select('id, username, avatar_url')
          .inFilter('id', idsToFetch);
      
      final fetchedIds = <String>{};
      for (var profile in response) {
        final id = profile['id'] as String;
        loadedProfiles[id] = UserProfile.fromMap(profile, null); 
        fetchedIds.add(id);
      }

      // Supabase'da profili topilmagan ID'larni keshga qo'shish
      final notFoundIds = idsToFetch.where((id) => !fetchedIds.contains(id));
      for (var id in notFoundIds) {
        // "Noma'lum" profilni keshga qo'shish (qayta yuklashni to'xtatadi)
        loadedProfiles[id] = UserProfile(id: id, username: "알 수 없는 사용자", email: null); 
      }
      
    } catch (e) {
      // Xato bo'lsa, xato xabarini ko'rsatish va bo'sh profil qo'shish
      debugPrint("프로필을 불러오는 중 오류가 발생했습니다: $e");
      for (var id in idsToFetch) {
         if (!loadedProfiles.containsKey(id)) {
            loadedProfiles[id] = UserProfile(id: id, username: "업로드 중 오류가 발생했습니다", email: null);
         }
      }
    }
    
    return loadedProfiles;
  }
  
  // Profilni tahrirlash dialogni ochish
  void _onSettingsPressed(UserProfile currentProfile) {
    _usernameController.text = currentProfile.username;
    _showProfileEditDialog(currentProfile);
  }

  // Rasm yuklash mantiqi (MOBIL UCHUN YANGILANGAN)
  Future<void> _uploadAvatar(String? currentAvatarUrl) async {
    final ImagePicker picker = ImagePicker();
    
    // 1. Rasm tanlash
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 300, 
      maxHeight: 300,
    );

    if (image == null) return; 
    
    try {
      // 2. Fayl ma'lumotlarini olish
      final fileBytes = await image.readAsBytes();
      final fileExtension = path.extension(image.name); // .jpg/.png kabi
      final mimeType = 'image/${fileExtension.substring(1)}'; // .jpg dan jpg ni olish
      
      final fileName = '${widget.userId}/${DateTime.now().millisecondsSinceEpoch}$fileExtension';

      // 3. Storage'ga yuklash
      await supabase.storage.from('avatars').uploadBinary(
            fileName, 
            fileBytes, 
            fileOptions: FileOptions(contentType: mimeType),
          );
      
      // Yuklash manzili (Public URL)
      final imageUrl = supabase.storage.from('avatars').getPublicUrl(fileName);

      // 4. Profiles jadvalini yangilash
      await supabase.from('profiles').update({'avatar_url': imageUrl}).eq('id', widget.userId);

      // 5. Eski rasmni o'chirish (agar mavjud bo'lsa)
      if (currentAvatarUrl != null && currentAvatarUrl.contains('avatars/')) {
        final oldFilePath = currentAvatarUrl.split('avatars/').last;
        try {
          // Supabase'dan path formatida o'chirish
          await supabase.storage.from('avatars').remove([oldFilePath]);
        } catch (e) {
          debugPrint("이전 이미지를 삭제하는 중 오류가 발생했습니다: $e");
        }
      }

      _showErrorSnackbar("이미지가 성공적으로 업데이트되었습니다!");
      
      // 6. Profilni qayta yuklash
      setState(() {
        _myProfileFuture = _loadMyProfile();
      });

      if (mounted) Navigator.of(context).pop(); // Dialogni yopish
      
    } catch (e) {
      _showErrorSnackbar("이미지 업로드 중 오류가 발생했습니다: $e");
      debugPrint("Rasm yuklashda xato: $e");
    }
  }


  // Username'ni yangilash
  Future<void> _updateUsername() async {
    final newUsername = _usernameController.text.trim();
    if (newUsername.isEmpty) return;

    try {
      await supabase.from('profiles').update({'username': newUsername}).eq('id', widget.userId);
      _showErrorSnackbar("사용자 이름이 성공적으로 업데이트되었습니다!");
      
      // Profilni qayta yuklash
      setState(() {
        _myProfileFuture = _loadMyProfile();
      });
      
      if (mounted) Navigator.of(context).pop();
      
    } catch (e) {
      _showErrorSnackbar("사용자 이름을 업데이트하는 중 오류가 발생했습니다: $e");
    }
  }

  // Profilni tahrirlash dialogni
  void _showProfileEditDialog(UserProfile currentProfile) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("프로필 편집"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.blue,
                backgroundImage: currentProfile.avatarUrl != null && currentProfile.avatarUrl!.isNotEmpty
                    ? NetworkImage(currentProfile.avatarUrl!)
                    : null,
                child: currentProfile.avatarUrl == null || currentProfile.avatarUrl!.isEmpty
                    ? Text(
                        // Username yoki Email bosh harfi
                        currentProfile.username.isNotEmpty 
                          ? currentProfile.username.substring(0, 1).toUpperCase()
                          : (currentProfile.email?.isNotEmpty == true ? currentProfile.email!.substring(0, 1).toUpperCase() : 'U'), 
                        style: const TextStyle(fontSize: 30, color: Colors.white),
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              // Username kiritish
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: '사용자 이름',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // Rasm yuklash tugmasi
              ElevatedButton.icon(
                onPressed: () => _uploadAvatar(currentProfile.avatarUrl),
                icon: const Icon(Icons.upload),
                label: const Text("프로필 사진 업로드"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("취소"),
            ),
            ElevatedButton(
              onPressed: _updateUsername,
              child: const Text("저장"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // AppBar'da Username'ni ko'rsatish
    return FutureBuilder<UserProfile>(
      future: _myProfileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
                appBar: null,
                body: Center(child: CircularProgressIndicator())
            );
        }
        
        // KUTILMAGAN XATO USHLASH (Foydalanuvchi yuborgan rasm bo'yicha)
        if (snapshot.hasError) {
          debugPrint("My Profile Load Error: ${snapshot.error}"); 
          return Scaffold(body: Center(child: 
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("프로필 로딩 오류가 발생했습니다!", style: TextStyle(color: Colors.red)),
                Text(snapshot.error.toString(), textAlign: TextAlign.center),
                const Text("\nSupabase RLS/Profiles 테이블 확인"),
              ],
            )
          ));
        }
        
        final myProfile = snapshot.data;
        if (myProfile == null) {
          return const Scaffold(body: Center(child: Text("프로필 로딩 실패")));
        }

        return Scaffold(
          appBar: AppBar(
            title: Text("${myProfile.username} "),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            actions: [
              // Profil sozlamalari (Tahrirlash uchun)
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => _onSettingsPressed(myProfile), // Dialogni chaqiradi
              ),
              // Chiqish (Logout) tugmasi
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: _logout,
              ),
            ],
          ),
          body: Column(
            children: [
              // Xabarlar ro'yxati
              Expanded(
                child: StreamBuilder<List<Message>>(
                  stream: supabase
                      .from('messages')
                      .stream(primaryKey: ['id'])
                      .order('created_at', ascending: true)
                      .map((data) => data.map(Message.fromMap).toList()),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text("오류: ${snapshot.error}"));
                    }
                    
                    final messages = snapshot.data ?? [];
                    
                    // Keshda yo'q profillarni yuklashni tekshirish
                    _checkAndLoadUserProfiles(messages);
                    
                    if (messages.isEmpty) {
                      return const Center(child: Text("현재 메시지가 없습니다."));
                    }
                    
                    // Eng oxirgi xabarga o'tish
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                       _scrollToBottom();
                    });
                    
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(12),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isMe = message.senderId == widget.userId;
                        
                        // Xabar o'qilganini belgilash
                        if (!isMe && !message.isRead) {
                          // O'qilganlik holatini yangilash, lekin bu ListView.builder ni bloklamaydi
                          Future.microtask(() async {
                            try {
                                await supabase
                                .from('messages')
                                .update({'is_read': true})
                                .eq('id', message.id);
                            } catch(e) {
                                debugPrint("Failed to update read status: $e");
                            }
                          });
                        }
                        
                        // Yuboruvchining profilini olish
                        final UserProfile senderProfile;

                        if (isMe) {
                            senderProfile = myProfile; 
                        } else {
                            // Keshdan olish yoki Loading profilini yaratish
                            senderProfile = _userProfiles[message.senderId] ?? 
                                UserProfile(
                                    id: message.senderId, 
                                    username: "...", // Loading holati
                                    email: null,
                                    avatarUrl: null,
                                );
                        }
                        
                        final time = timeago.format(message.createdAt.toLocal());

                        return _MessageBubble(
                          message: message.message,
                          isMe: isMe,
                          profile: senderProfile, 
                          isRead: message.isRead,
                          time: time,
                        );
                      },
                    );
                  },
                ),
              ),
              
              // Xabar yuborish maydoni
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0, left: 8.0, right: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: '메시지 전송...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        onSubmitted: (value) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.blue),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}


// Xabar pufakchasi (Message Bubble)
class _MessageBubble extends StatefulWidget {
  final String message;
  final bool isMe;
  final UserProfile profile; // Profil ma'lumotlari
  final bool isRead;
  final String time;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.profile,
    required this.isRead,
    required this.time,
  });

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble> {
  // Rasm yuklanishida xato bo'lsa, uni true ga o'rnatamiz
  bool _avatarLoadError = false; 

  // Rasm mavjudligini tekshirish funksiyasi
  bool hasAvatar() {
    return widget.profile.avatarUrl != null && widget.profile.avatarUrl!.isNotEmpty;
  }
  
  // Rasm ko'rsatuvchi widget (bosh harfni qaytaradi agar yuklanmasa)
  Widget _buildAvatar() {
    // 1. Loading holati
    if (widget.profile.username == "...") {
       return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)); 
    }
    
    // 2. Avatar mavjud, yuklashga urinish
    if (hasAvatar() && !_avatarLoadError) {
        return Image.network(
          widget.profile.avatarUrl!,
          fit: BoxFit.cover, 
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child; 
            return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)); 
          },
          errorBuilder: (context, error, stackTrace) {
            // Rasm yuklanmasa, xato holatini o'rnatish
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_avatarLoadError) {
                setState(() {
                  _avatarLoadError = true;
                });
              }
            });
            // Bosh harfni qaytarish (quyidagi 3-qadamga tushadi)
            return _getInitialText();
          },
        );
    }
    
    // 3. Avatar yo'q, yuklashda xato yoki NotFound/Error (bosh harf)
    return _getInitialText();
  }

  Widget _getInitialText() {
    // Username bo'sh bo'lsa, '?' ko'rsatish
     String initial = widget.profile.username.isNotEmpty 
        ? widget.profile.username.substring(0, 1).toUpperCase() 
        : '?'; 
          
    return Text(
      initial,
      style: const TextStyle(fontSize: 14, color: Colors.white),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final color = widget.isMe ? Colors.blue : Colors.grey[300];
    final textColor = widget.isMe ? Colors.white : Colors.black;
    
    // Xabar pufakchasi to'liq Row ichida bo'ladi
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar (faqat qabul qiluvchida)
          if (!widget.isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue,
              child: _buildAvatar(), 
            ),
            const SizedBox(width: 8),
          ],
          
          // Xabar Content
          Column(
            crossAxisAlignment: widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // Username va Vaqt
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Yuboruvchi bo'lsa: O'qilganlik Ikonkasi -> Vaqt -> Username
                    if (widget.isMe) ...[
                      // O'qilganlik Ikonkasi
                      Icon(
                        widget.isRead ? Icons.done_all : Icons.done,
                        size: 14, 
                        color: widget.isRead ? Colors.lightBlue : Colors.grey[400], 
                      ),
                      const SizedBox(width: 4), 
                      
                      Text(widget.time, style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                      const SizedBox(width: 8),
                    ],
                    // Username
                    Text(
                      widget.profile.username, 
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    // Qabul qiluvchi bo'lsa: Username -> Vaqt
                    if (!widget.isMe) ...[
                      const SizedBox(width: 8),
                      Text(widget.time, style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                    ],
                  ],
                ),
              ),
              
              // Xabar pufakchasi
              Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(12),
                    topRight: const Radius.circular(12),
                    bottomLeft: widget.isMe ? const Radius.circular(12) : const Radius.circular(4),
                    bottomRight: widget.isMe ? const Radius.circular(4) : const Radius.circular(12),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Text(
                  widget.message,
                  style: TextStyle(color: textColor),
                ),
              ),
            ],
          ),
          
          // Avatar (faqat yuboruvchida)
          if (widget.isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue,
              child: _buildAvatar(), 
            ),
          ],
        ],
      ),
    );
  }
}