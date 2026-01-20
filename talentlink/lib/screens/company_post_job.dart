import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyPostJobScreen extends StatefulWidget {
  const CompanyPostJobScreen({super.key});

  @override
  State<CompanyPostJobScreen> createState() => _CompanyPostJobScreenState();
}

class _CompanyPostJobScreenState extends State<CompanyPostJobScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _skillsController = TextEditingController();
  final _locationController = TextEditingController();

  bool _posting = false;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<void> _postJob() async {
    if (!_formKey.currentState!.validate()) return;

    final user = _auth.currentUser;
    if (user == null) return;

    setState(() {
      _posting = true;
    });

    // get company info
    final companyDoc =
        await _firestore.collection('users').doc(user.uid).get();

    final companyName = companyDoc.data()?['companyName'] ?? 'Unknown Company';

    await _firestore.collection('jobs').add({
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'skills': _skillsController.text.trim(),
      'location': _locationController.text.trim(),
      'companyId': user.uid,
      'companyName': companyName,
      'createdAt': FieldValue.serverTimestamp(),
    });

    setState(() {
      _posting = false;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Job posted successfully')),
    );

    _formKey.currentState!.reset();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _skillsController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildField('Job Title', _titleController),
            _buildField(
              'Job Description',
              _descriptionController,
              maxLines: 4,
            ),
            _buildField(
              'Required Skills',
              _skillsController,
              hint: 'Flutter, Firebase, REST APIs',
            ),
            _buildField(
              'Location',
              _locationController,
              hint: 'Remote / On-site / Hybrid',
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _posting ? null : _postJob,
                child: _posting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Post Job'),
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
