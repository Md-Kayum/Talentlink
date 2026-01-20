import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateLearningPostScreen extends StatefulWidget {
  const CreateLearningPostScreen({super.key});

  @override
  State<CreateLearningPostScreen> createState() =>
      _CreateLearningPostScreenState();
}

class _CreateLearningPostScreenState extends State<CreateLearningPostScreen> {
  final _controller = TextEditingController();
  bool _posting = false;

  Future<void> _submitPost() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _posting = true);

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final name = userDoc.data()?['name'] ?? 'Student';

    await FirebaseFirestore.instance.collection('feed_posts').add({
      'authorId': user.uid,
      'authorName': name,
      'authorRole': 'student',
      'type': 'learning',
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    setState(() => _posting = false);

    if (!mounted) return;

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Learning Update'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText:
                    'What did you learn recently? How did you learn it?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _posting ? null : _submitPost,
                child: _posting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Post'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
