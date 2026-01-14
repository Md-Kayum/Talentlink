import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class StudentHome extends StatelessWidget {
  const StudentHome({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService _authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Home"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.logout();
              Navigator.pop(context); // go back to login
            },
          )
        ],
      ),
      body: const Center(
        child: Text("Welcome Student!"),
      ),
    );
  }
}
