import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'student_profile.dart';
import 'student_jobs.dart';
import 'student_applications.dart';
import 'create_learning_post.dart';

class StudentHome extends StatefulWidget {
  const StudentHome({super.key});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  int _currentIndex = 0;

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  final List<Widget> _pages = const [
    _StudentFeedPage(),
    StudentJobsScreen(),
    StudentApplicationsScreen(),
    StudentProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TalentLink'),
        actions: [
          if (_currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreateLearningPostScreen(),
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Feed'),
          BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Jobs'),
          BottomNavigationBarItem(
              icon: Icon(Icons.assignment), label: 'Applications'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

/* ================= FEED PAGE ================= */

class _StudentFeedPage extends StatelessWidget {
  const _StudentFeedPage();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('feed_posts')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, feedSnapshot) {
        if (!feedSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('jobs')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, jobSnapshot) {
            if (!jobSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final List<_FeedItem> items = [];

            for (final doc in feedSnapshot.data!.docs) {
              final d = doc.data() as Map<String, dynamic>;
              items.add(
                _FeedItem(
                  id: doc.id,
                  type: 'learning',
                  title: d['authorName'] ?? 'Student',
                  subtitle: d['text'] ?? '',
                  timestamp: d['createdAt'],
                  likedBy: List.from(d['likedBy'] ?? []),
                  interestedBy: const [],
                ),
              );
            }

            for (final doc in jobSnapshot.data!.docs) {
              final d = doc.data() as Map<String, dynamic>;
              items.add(
                _FeedItem(
                  id: doc.id,
                  type: 'job',
                  title: d['companyName'] ?? '',
                  subtitle: d['title'] ?? '',
                  timestamp: d['createdAt'],
                  likedBy: const [],
                  interestedBy: List.from(d['interestedBy'] ?? []),
                ),
              );
            }

            items.sort((a, b) {
              final at = a.timestamp?.millisecondsSinceEpoch ?? 0;
              final bt = b.timestamp?.millisecondsSinceEpoch ?? 0;
              return bt.compareTo(at);
            });

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return _FeedCard(item: items[index]);
              },
            );
          },
        );
      },
    );
  }
}

/* ================= FEED ITEM MODEL ================= */

class _FeedItem {
  final String id;
  final String type;
  final String title;
  final String subtitle;
  final Timestamp? timestamp;
  final List likedBy;
  final List interestedBy;

  _FeedItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.likedBy,
    required this.interestedBy,
  });
}

/* ================= FEED CARD ================= */

class _FeedCard extends StatelessWidget {
  final _FeedItem item;

  const _FeedCard({required this.item});

  Color get _accentColor =>
      item.type == 'job' ? const Color(0xFF26A69A) : const Color(0xFF1E88E5);

  String get _roleLabel =>
      item.type == 'job' ? 'COMPANY' : 'STUDENT';

  IconData get _icon =>
      item.type == 'job' ? Icons.business : Icons.school;

 Future<void> _toggleInterested() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null || item.type != 'job') return;

  final ref = FirebaseFirestore.instance.collection('jobs').doc(item.id);

  await FirebaseFirestore.instance.runTransaction((txn) async {
    final snap = await txn.get(ref);
    if (!snap.exists) return;

    final data = snap.data()!;
    final List interestedBy = List.from(data['interestedBy'] ?? []);
    final Map<String, dynamic> applicationStatus =
        Map<String, dynamic>.from(data['applicationStatus'] ?? {});

    // toggle interested
    if (interestedBy.contains(user.uid)) {
      interestedBy.remove(user.uid);
    } else {
      interestedBy.add(user.uid);
    }

    // 🔥 CREATE APPLICATION ON APPLY
    if (!applicationStatus.containsKey(user.uid)) {
      applicationStatus[user.uid] = 'pending';
    }

    txn.update(ref, {
      'interestedBy': interestedBy,
      'applicationStatus': applicationStatus,
    });
  });
}


  Future<void> _toggleLike() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || item.type != 'learning') return;

    final ref =
        FirebaseFirestore.instance.collection('feed_posts').doc(item.id);

    FirebaseFirestore.instance.runTransaction((txn) async {
      final snap = await txn.get(ref);
      if (!snap.exists) return;

      final data = snap.data();
      if (data == null) return;

      final List list = List.from(data['likedBy'] ?? []);

      if (list.contains(user.uid)) {
        list.remove(user.uid);
      } else {
        list.add(user.uid);
      }

      txn.update(ref, {'likedBy': list});
    });
  }

  void _openComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CommentSheet(postId: item.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final liked = user != null && item.likedBy.contains(user.uid);
    final interested = user != null && item.interestedBy.contains(user.uid);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: _accentColor, width: 4)),
      ),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: _accentColor.withOpacity(0.15),
                    child: Icon(_icon, color: _accentColor),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _RoleBadge(label: _roleLabel, color: _accentColor),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(item.subtitle),
              const SizedBox(height: 12),

              if (item.type == 'learning')
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        liked
                            ? Icons.thumb_up
                            : Icons.thumb_up_alt_outlined,
                        color: _accentColor,
                      ),
                      onPressed: _toggleLike,
                    ),
                    Text('${item.likedBy.length}'),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _openComments(context),
                      child: const Text('Comments'),
                    ),
                  ],
                ),

              if (item.type == 'job')
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: _toggleInterested,
                      icon: Icon(
                        interested
                            ? Icons.check_circle
                            : Icons.check_circle_outline,
                        color: _accentColor,
                      ),
                      label: Text(
                        interested ? 'Interested' : 'Mark Interested',
                        style: TextStyle(color: _accentColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${item.interestedBy.length} interested'),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ================= ROLE BADGE ================= */

class _RoleBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _RoleBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/* ================= COMMENTS ================= */

class _CommentSheet extends StatefulWidget {
  final String postId;

  const _CommentSheet({required this.postId});

  @override
  State<_CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<_CommentSheet> {
  final _controller = TextEditingController();

  Future<void> _addComment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _controller.text.trim().isEmpty) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    await FirebaseFirestore.instance
        .collection('feed_posts')
        .doc(widget.postId)
        .collection('comments')
        .add({
      'userId': user.uid,
      'userName': userDoc.data()?['name'] ?? 'User',
      'text': _controller.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('feed_posts')
                .doc(widget.postId)
                .collection('comments')
                .orderBy('createdAt')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const CircularProgressIndicator();
              }

              return SizedBox(
                height: 300,
                child: ListView(
                  children: snapshot.data!.docs.map((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(d['userName'] ?? ''),
                      subtitle: Text(d['text'] ?? ''),
                    );
                  }).toList(),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration:
                        const InputDecoration(hintText: 'Add a comment'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _addComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
