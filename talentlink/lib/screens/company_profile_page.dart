import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyProfilePage extends StatefulWidget {
  const CompanyProfilePage({super.key});

  @override
  State<CompanyProfilePage> createState() => _CompanyProfilePageState();
}

class _CompanyProfilePageState extends State<CompanyProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final _companyNameCtrl = TextEditingController();
  final _aboutCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _industryCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  final String _uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(_uid).get();

    final data = doc.data();
    if (data != null) {
      _companyNameCtrl.text = data['companyName'] ?? '';
      _aboutCtrl.text = data['about'] ?? '';
      _locationCtrl.text = data['location'] ?? '';
      _industryCtrl.text = data['industry'] ?? '';
      _websiteCtrl.text = data['website'] ?? '';
    }

    setState(() => _loading = false);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    await FirebaseFirestore.instance.collection('users').doc(_uid).update({
      'companyName': _companyNameCtrl.text.trim(),
      'about': _aboutCtrl.text.trim(),
      'location': _locationCtrl.text.trim(),
      'industry': _industryCtrl.text.trim(),
      'website': _websiteCtrl.text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    setState(() => _saving = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Company profile updated')),
    );
  }

  @override
  void dispose() {
    _companyNameCtrl.dispose();
    _aboutCtrl.dispose();
    _locationCtrl.dispose();
    _industryCtrl.dispose();
    _websiteCtrl.dispose();
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
            _field('Company Name', _companyNameCtrl),
            _field('About Company', _aboutCtrl, maxLines: 4),
            _field('Location', _locationCtrl),
            _field('Industry', _industryCtrl),
            _field('Website / Contact', _websiteCtrl),

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

  Widget _field(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: (v) =>
            v == null || v.isEmpty ? 'Required field' : null,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
