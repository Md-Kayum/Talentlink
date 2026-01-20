import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _aboutController = TextEditingController();
  final _skillsController = TextEditingController();
  final _educationController = TextEditingController();
  final _portfolioController = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _uid;

  @override
  void initState() {
    super.initState();

    final user = _auth.currentUser;
    if (user != null) {
      _uid = user.uid;
      _loadProfile();
    } else {
      _loading = false;
    }
  }

  Future<void> _loadProfile() async {
    if (_uid == null) return;

    final doc = await _firestore.collection('users').doc(_uid).get();

    if (doc.exists) {
      final data = doc.data()!;
      _nameController.text = data['name'] ?? '';
      _aboutController.text = data['about'] ?? '';
      _skillsController.text = data['skills'] ?? '';
      _educationController.text = data['education'] ?? '';
      _portfolioController.text = data['portfolio'] ?? '';
    }

    setState(() {
      _loading = false;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_uid == null) return;

    setState(() {
      _saving = true;
    });

    await _firestore.collection('users').doc(_uid).update({
      'name': _nameController.text.trim(),
      'about': _aboutController.text.trim(),
      'skills': _skillsController.text.trim(),
      'education': _educationController.text.trim(),
      'portfolio': _portfolioController.text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    setState(() {
      _saving = false;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully')),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _aboutController.dispose();
    _skillsController.dispose();
    _educationController.dispose();
    _portfolioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildField('Full Name', _nameController),

            _buildField(
              'About Me',
              _aboutController,
              maxLines: 4,
              hint: 'Tell recruiters about yourself',
            ),

            _buildField('Skills (comma separated)', _skillsController),

            _buildField(
              'Education',
              _educationController,
              maxLines: 2,
            ),

            _buildField(
              'Portfolio Links',
              _portfolioController,
              hint: 'LinkedIn, GitHub, website',
              maxLines: 2,
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveProfile,
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
        validator: (v) =>
            v == null || v.isEmpty ? 'This field is required' : null,
      ),
    );
  }
}
