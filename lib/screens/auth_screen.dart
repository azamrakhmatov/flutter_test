import 'package:flutter/material.dart';
import 'chat_page.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _userController = TextEditingController();

  void _enterChat() {
    final userId = _userController.text.trim();
    if (userId.isEmpty) return;

 Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => ChatPage(senderId: userId), //  senderId deb yozing
  ),
);

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login to Chat"),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "유저 이름이나 아이디를 입력해주세요",
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _userController,
              decoration: const InputDecoration(
                hintText: "유저 123",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _enterChat,
              child: const Text("채팅 접속"),
            )
          ],
        ),
      ),
    );
  }
}

