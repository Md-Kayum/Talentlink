import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyApplicantsScreen extends StatelessWidget {
  final String jobId;
  final String jobTitle;

  const CompanyApplicantsScreen({
    super.key,
    required this.jobId,
    required this.jobTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(jobTitle),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('applications')
            .where('jobId', isEqualTo: jobId)
            // ❌ REMOVED orderBy('appliedAt')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No students have applied yet'),
            );
          }

          final applications = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final appDoc = applications[index];
              final appData = appDoc.data() as Map<String, dynamic>;

              return _ApplicantCard(
                applicationId: appDoc.id,
                studentId: appData['studentId'],
                status: appData['status'] ?? 'applied',
                jobId: jobId,
              );
            },
          );
        },
      ),
    );
  }
}

/* ================= APPLICANT CARD ================= */

class _ApplicantCard extends StatelessWidget {
  final String applicationId;
  final String studentId;
  final String status;
  final String jobId;

  const _ApplicantCard({
    required this.applicationId,
    required this.studentId,
    required this.status,
    required this.jobId,
  });

  Future<void> _updateStatus(String newStatus) async {
    final batch = FirebaseFirestore.instance.batch();

    final applicationRef =
        FirebaseFirestore.instance.collection('applications').doc(applicationId);

    final jobRef =
        FirebaseFirestore.instance.collection('jobs').doc(jobId);

    // ✅ Source of truth
    batch.update(applicationRef, {'status': newStatus});

    // ✅ Optional sync (safe)
    batch.update(jobRef, {
      'applicationStatus.$studentId': newStatus,
    });

    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(studentId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final user = snapshot.data!.data() as Map<String, dynamic>?;

        if (user == null) {
          return const SizedBox.shrink();
        }

        Color statusColor;
        switch (status) {
          case 'shortlisted':
            statusColor = Colors.green;
            break;
          case 'rejected':
            statusColor = Colors.red;
            break;
          default:
            statusColor = Colors.orange;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['name'] ?? 'Student',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),

                if ((user['skills'] ?? '').toString().isNotEmpty)
                  Text('Skills: ${user['skills']}'),

                if ((user['education'] ?? '').toString().isNotEmpty)
                  Text('Education: ${user['education']}'),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Chip(
                      label: Text(
                        status.toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: statusColor,
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: status == 'shortlisted'
                          ? null
                          : () => _updateStatus('shortlisted'),
                      child: const Text('Shortlist'),
                    ),
                    TextButton(
                      onPressed: status == 'rejected'
                          ? null
                          : () => _updateStatus('rejected'),
                      child: const Text(
                        'Reject',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
