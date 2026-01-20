import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/student_home.dart';
import 'screens/company_home.dart';
import 'screens/admin_home.dart';

/// ===============================
/// GLOBAL THEME HOLDER
/// ===============================
ThemeData _currentTheme = _studentTheme;
String? _lastAppliedRole;

/// 🔧 ADDITION: FORCE ROOT REBUILD
final ValueNotifier<int> _appRebuildNotifier = ValueNotifier(0);

/// ===============================
/// STUDENT THEME (Blue – from logo)
/// ===============================
final ThemeData _studentTheme = ThemeData(
  primaryColor: const Color(0xFF1E88E5),
  scaffoldBackgroundColor: const Color(0xFFF5F9FF),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF1E88E5),
    foregroundColor: Colors.white,
  ),
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF1E88E5),
  ),
);

/// ===============================
/// COMPANY THEME (Teal – from logo)
/// ===============================
final ThemeData _companyTheme = ThemeData(
  primaryColor: const Color(0xFF26A69A),
  scaffoldBackgroundColor: const Color(0xFFF3FBF9),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF26A69A),
    foregroundColor: Colors.white,
  ),
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF26A69A),
  ),
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    /// 🔧 WRAP MaterialApp so it can rebuild
    return ValueListenableBuilder<int>(
      valueListenable: _appRebuildNotifier,
      builder: (context, _, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'TalentLink',
          theme: _currentTheme,
          home: const AuthGate(),
        );
      },
    );
  }
}

/// ===============================
/// AUTH GATE (UNCHANGED LOGIC + ADDITIONS)
/// ===============================
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  void _applyThemeOnce(String role) {
    if (_lastAppliedRole == role) return;

    _lastAppliedRole = role;
    _currentTheme =
        role == 'company' ? _companyTheme : _studentTheme;

    /// 🔧 FORCE ROOT REBUILD
    _appRebuildNotifier.value++;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        final user = authSnap.data;

        if (user == null) {
          _currentTheme = _studentTheme;
          _lastAppliedRole = null;

          /// 🔧 FORCE ROOT REBUILD
          _appRebuildNotifier.value++;

          return const LoginScreen();
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, userSnap) {
            if (!userSnap.hasData) {
              return const _LoadingScreen();
            }

            if (!userSnap.data!.exists) {
              return const _LoadingScreen();
            }

            final data =
                userSnap.data!.data() as Map<String, dynamic>;
            final role = data['role'] as String?;

            if (role == null) {
              return const _LoadingScreen();
            }

            _applyThemeOnce(role);

            if (role == 'student') return const StudentHome();
            if (role == 'company') return const CompanyHome();
            if (role == 'admin') return const AdminHome();

            return _ErrorScreen(
              message: "Unknown role: $role",
              actionText: "Go to Login",
              onAction: () async {
                await FirebaseAuth.instance.signOut();
              },
            );
          },
        );
      },
    );
  }
}

/// ===============================
/// LOADING SCREEN
/// ===============================
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF143068),
      body: Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}

/// ===============================
/// ERROR SCREEN
/// ===============================
class _ErrorScreen extends StatelessWidget {
  final String message;
  final String actionText;
  final VoidCallback onAction;

  const _ErrorScreen({
    required this.message,
    required this.actionText,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF143068),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: onAction,
                  child: Text(actionText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
