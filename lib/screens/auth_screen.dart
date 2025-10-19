import 'package:exam/screens/chat_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Supabase client instance
final supabase = Supabase.instance.client;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  // Xatolik xabarini ko'rsatish funksiyasi
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  // Kirish (Login)
  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        _showErrorSnackBar("이메일과 비밀번호는 필수 입력 항목입니다.");
        return;
      }

      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Null tekshiruvi: Agar foydalanuvchi ma'lumotlari mavjud bo'lmasa, xato beramiz.
      if (response.user == null || response.session == null) {
        _showErrorSnackBar("이메일/비밀번호가 올바르지 않습니다.");
        return;
      }

      // Muvaffaqiyatli kirish: ChatPage ga yo'naltirish
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => ChatPage(userId: response.user!.id),
          ),
          (route) => false,
        );
      }
    } on AuthException catch (e) {
      _showErrorSnackBar("로그인에 실패했습니다: ${e.message}");
    } catch (e) {
      _showErrorSnackBar("예상치 못한 오류로 로그인할 수 없습니다.");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Ro'yxatdan o'tish (Sign Up)
  Future<void> _signUp() async {
    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final username = _usernameController.text.trim();

      if (email.isEmpty || password.isEmpty || username.isEmpty) {
        _showErrorSnackBar("모든 항목을 입력해 주세요.");
        return;
      }

      // 1. Supabase Auth da ro'yxatdan o'tish
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      // Null tekshiruvi: Agar Auth user yoki session qaytmasa, jarayon muvaffaqiyatsiz
      if (response.user == null) {
         _showErrorSnackBar("회원가입에 실패했습니다. 해당 이메일은 이미 사용 중일 수 있습니다.");
         return;
      }

      final userId = response.user!.id;

      // 2. profiles jadvaliga username kiritish
      await supabase.from('profiles').insert({
        'id': userId,
        'username': username,
        'avatar_url': null,
      });

      // Muvaffaqiyatli ro'yxatdan o'tish: ChatPage ga yo'naltirish
      if (mounted) {
        _showErrorSnackBar("Muvaffaqiyatli ro'yxatdan o'tildi!");
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => ChatPage(userId: userId),
          ),
          (route) => false,
        );
      }
    } on AuthException catch (e) {
      _showErrorSnackBar("가입이 성공적으로 완료되었습니다: ${e.message}");
    } catch (e) {
      _showErrorSnackBar("예상치 못한 오류: 사용자 이름 또는 프로필을 생성할 수 없습니다.");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? "로그인" : "회원가입"),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isLogin ? "로그인 정보를 입력해 주세요." : "계정 생성",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // Email
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "이메일",
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 12),

              // Parol
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "비밀번호",
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 12),

              // Username (Faqat Ro'yxatdan o'tish uchun)
              if (!_isLogin) ...[
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: "사용자 이름",
                    hintText: "채팅에서 표시할 이름",
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Asosiy Tugma (Login/Register)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : _isLogin
                          ? _signIn
                          : _signUp,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _isLogin ? "입장" : "회원가입",
                          style: const TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 10),

              // Holatni almashtirish tugmasi
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        setState(() {
                          _isLogin = !_isLogin;
                        });
                      },
                child: Text(
                  _isLogin ? "계정이 없나요? 회원가입하기" : "이미 계정이 있나요? 로그인하기",
                  style: const TextStyle(color: Colors.blueGrey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

