import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth_screen.dart'; // Yangilangan AuthScreen
import 'screens/chat_page.dart'; // ChatPage

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env faylni yuklash
  await dotenv.load(fileName: ".env");

  // Supabase sozlamalari
  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null || supabaseAnonKey == null) {
    throw Exception("SUPABASE_URL 또는 SUPABASE_ANON_KEY를 찾을 수 없습니다. .env 파일을 확인하세요!");
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // Boshlang'ich sahifa SplashPage bo'lishi kerak
      home: const SplashPage(),
      // Qo'shimcha yo'nalishlar (Routerda ishlatilmaydi, lekin mavjud bo'lsin)
      routes: {
        '/login': (context) => const AuthScreen(),
        // ChatPage router orqali emas, argument bilan chaqiriladi
      },
    );
  }
}

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  // Tizimga kirish holatiga qarab yo'naltirish
  Future<void> _redirect() async {
    // UI yuklanishini kutish
    await Future.delayed(Duration.zero); 

    final session = Supabase.instance.client.auth.currentSession;
    
    if (session == null) {
      // Sessiya yo'q -> AuthScreen ga o'tish
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const AuthScreen()),
            (route) => false);
      }
    } else {
      // Sessiya bor -> ChatPage ga o'tish (TO'G'RI PARAMETR: userId)
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              // userId nomli to'g'ri parametrni ishlatish
              builder: (context) => ChatPage(userId: session.user.id) 
            ),
            (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Splash screen faqat loading ko'rsatadi
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}