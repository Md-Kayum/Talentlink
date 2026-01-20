import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentApplicationsScreen extends StatelessWidget {
  const StudentApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('Not logged in'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('applications')
          .where('studentId', isEqualTo: user.uid)
          .orderBy('appliedAt', descending: true)
          .snapshots(),
      builder: (context, appSnapshot) {
        if (appSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!appSnapshot.hasData || appSnapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('You have not applied to any jobs yet'),
          );
        }

        final applications = appSnapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: applications.length,
          itemBuilder: (context, index) {
            final appData = applications[index].data() as Map<String, dynamic>;

            final String jobId = (appData['jobId'] ?? '').toString();
            final String appStatusRaw = (appData['status'] ?? 'applied').toString();

            if (jobId.isEmpty) {
              return const SizedBox();
            }

            // We fetch the job to show job details AND to optionally read job.applicationStatus[uid]
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('jobs').doc(jobId).get(),
              builder: (context, jobSnapshot) {
                if (jobSnapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: LinearProgressIndicator(),
                  );
                }

                if (!jobSnapshot.hasData || !jobSnapshot.data!.exists) {
                  return const SizedBox();
                }

                final jobData = jobSnapshot.data!.data() as Map<String, dynamic>;

                // ✅ Display status priority:
                // 1) job.applicationStatus[uid] if present (company might be updating jobs)
                // 2) applications.status (source of truth for option B)
                String displayStatus = appStatusRaw;

                final Map<String, dynamic> jobStatusMap =
                    Map<String, dynamic>.from(jobData['applicationStatus'] ?? {});

                if (jobStatusMap.containsKey(user.uid)) {
                  displayStatus = (jobStatusMap[user.uid] ?? appStatusRaw).toString();
                }

                // Normalize: 'applied' -> Pending
                if (displayStatus == 'applied') {
                  displayStatus = 'pending';
                }

                return _ApplicationCard(
                  jobTitle: (jobData['title'] ?? '').toString(),
                  companyName: (jobData['companyName'] ?? '').toString(),
                  status: displayStatus,
                );
              },
            );
          },
        );
      },
    );
  }
}

/* ================= APPLICATION CARD ================= */

class _ApplicationCard extends StatelessWidget {
  final String jobTitle;
  final String companyName;
  final String status;

  const _ApplicationCard({
    required this.jobTitle,
    required this.companyName,
    required this.status,
  });

  Color get _statusColor {
    switch (status) {
      case 'shortlisted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  String get _statusLabel {
    switch (status) {
      case 'shortlisted':
        return 'Shortlisted';
      case 'rejected':
        return 'Rejected';
      case 'pending':
      default:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              jobTitle,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              companyName,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Status:'),
                const SizedBox(width: 8),
                Chip(
                  label: Text(
                    _statusLabel,
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: _statusColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
