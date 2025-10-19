import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _usernameController = TextEditingController();
  
  String? _currentUsername;
  String? _avatarUrl;
  bool _isLoading = false;
  File? _newAvatarFile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // --- Profilni yuklash funksiyasi ---
  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final userId = _supabase.auth.currentUser!.id;
    try {
      final response = await _supabase
          .from('profiles')
          .select('username, avatar_url')
          .eq('id', userId)
          .single();

      if (response != null) {
        _currentUsername = response['username'] as String?;
        _avatarUrl = response['avatar_url'] as String?;
        _usernameController.text = _currentUsername ?? '';
      }
    } catch (e) {
      _showErrorSnackBar('프로필 저장 중 오류 : $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- Yangi rasm tanlash funksiyasi ---
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (pickedFile != null) {
      setState(() {
        _newAvatarFile = File(pickedFile.path);
      });
    }
  }

  // --- Profilni saqlash funksiyasi ---
  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    final newUsername = _usernameController.text.trim();
    final userId = _supabase.auth.currentUser!.id;
    String? finalAvatarUrl = _avatarUrl;
    
    try {
      // 1. Agar yangi rasm tanlangan bo'lsa, uni yuklaymiz
      if (_newAvatarFile != null) {
        final avatarFileName = 'avatar_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final imageExtension = _newAvatarFile!.path.split('.').last;
        final imageBytes = await _newAvatarFile!.readAsBytes();

        final storageResponse = await _supabase.storage.from('avatars').uploadBinary(
          avatarFileName, 
          imageBytes,
          fileOptions: FileOptions(
            contentType: 'image/$imageExtension',
            cacheControl: '3600',
          ),
        );
        
        // Storage da rasm joylashgan public URL ni olamiz
        finalAvatarUrl = _supabase.storage.from('avatars').getPublicUrl(avatarFileName);
      }

      // 2. Ma'lumotlarni Supabase Profiles jadvalida yangilash
      await _supabase.from('profiles').update({
        'username': newUsername,
        'avatar_url': finalAvatarUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
      
      setState(() {
        _currentUsername = newUsername;
        _avatarUrl = finalAvatarUrl;
        _newAvatarFile = null;
      });
      
      _showSuccessSnackBar('프로필이 성공적으로 변경되었습니다!');
    } catch (e) {
      _showErrorSnackBar('저장 중 오류: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- UI Yordamchi Funksiyalar ---
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  // --- UI Qismi ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("프로필 설정"),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading && _currentUsername == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Avatar/Rasm qismi ---
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey.shade300,
                        backgroundImage: _newAvatarFile != null
                            ? FileImage(_newAvatarFile!)
                            : (_avatarUrl != null 
                                ? NetworkImage(_avatarUrl!) 
                                : null) as ImageProvider?,
                        child: _newAvatarFile == null && _avatarUrl == null
                            ? const Icon(Icons.person, size: 60, color: Colors.white)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Center(
                    child: Text(
                      "사진을 선택하려면 누르세요",
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- Username maydoni ---
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: "사용자 이름",
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- Saqlash tugmasi ---
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "저장",
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
