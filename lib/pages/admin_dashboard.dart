import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import your newly created components from the sub-folder:
import 'dashboard_admin/admin_background.dart';
import 'dashboard_admin/admin_navbar.dart';
import 'dashboard_admin/admin_dialogs.dart';
import 'dashboard_admin/application_card.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with TickerProviderStateMixin {
  
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  void _checkAuth() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null && mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    });
  }

  void _toggleSelection(String docId) {
    setState(() {
      if (_selectedIds.contains(docId)) {
        _selectedIds.remove(docId);
      } else {
        _selectedIds.add(docId);
      }
    });
  }

  void _toggleSelectAll(List<QueryDocumentSnapshot> docs) {
    setState(() {
      if (_selectedIds.length == docs.length && docs.isNotEmpty) {
        _selectedIds.clear();
      } else {
        _selectedIds.clear();
        for (var doc in docs) {
          _selectedIds.add(doc.id);
        }
      }
    });
  }

  Future<void> _verifyUser(String docId, String currentStatus, String fullName, String email) async {
    final newStatus = currentStatus == 'approved' ? 'pending' : 'approved';
    final isApproving = newStatus == 'approved';

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (ctx) => VerifyConfirmDialog(
        fullName: fullName,
        email: email,
        isApproving: isApproving,
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await FirebaseFirestore.instance.collection('applications').doc(docId).update({
        'status': newStatus,
        'verifiedAt': isApproving ? FieldValue.serverTimestamp() : FieldValue.delete(),
        'verifiedBy': isApproving ? FirebaseAuth.instance.currentUser?.uid : FieldValue.delete(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            Icon(isApproving ? Icons.verified_rounded : Icons.undo_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text(isApproving ? '$fullName has been verified' : '$fullName has been set back to pending', style: const TextStyle(fontWeight: FontWeight.w600)),
          ]),
          backgroundColor: isApproving ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(20),
          duration: const Duration(seconds: 4),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
      }
    }
  }

  Future<void> _gradeExam(String docId, String fullName, String email, String currentExamStatus) async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => ExamGradeDialog(
        fullName: fullName,
        email: email,
        currentExamStatus: currentExamStatus,
      ),
    );

    if (result == null || !mounted) return;

    try {
      await FirebaseFirestore.instance.collection('applications').doc(docId).update({
        'onboardingExam.status'   : result,
        'onboardingExam.gradedAt' : FieldValue.serverTimestamp(),
        'onboardingExam.gradedBy' : FirebaseAuth.instance.currentUser?.uid,
      });

      if (mounted) {
        final passed = result == 'passed';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            Icon(passed ? Icons.check_circle_rounded : Icons.cancel_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text(passed ? '$fullName marked as PASSED' : '$fullName marked as FAILED', style: const TextStyle(fontWeight: FontWeight.w600)),
          ]),
          backgroundColor: passed ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(20),
          duration: const Duration(seconds: 4),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error grading exam: $e'), backgroundColor: Colors.redAccent));
      }
    }
  }

  Future<void> _deleteRecord(String docId) async {
    bool confirm = await _showDeleteConfirmDialog("Delete this application?");
    if (confirm) {
      await FirebaseFirestore.instance.collection('applications').doc(docId).delete();
      if (mounted) {
        setState(() => _selectedIds.remove(docId));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Record deleted"), backgroundColor: Colors.redAccent));
      }
    }
  }

  Future<void> _deleteSelectedRecords() async {
    if (_selectedIds.isEmpty) return;
    bool confirm = await _showDeleteConfirmDialog("Delete ${_selectedIds.length} selected records?");
    if (confirm) {
      final batch = FirebaseFirestore.instance.batch();
      for (final id in _selectedIds) {
        batch.delete(FirebaseFirestore.instance.collection('applications').doc(id));
      }
      await batch.commit();
      if (mounted) {
        setState(() => _selectedIds.clear());
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Selected records deleted"), backgroundColor: Colors.redAccent));
      }
    }
  }

  Future<bool> _showDeleteConfirmDialog(String title) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: const Text("This action cannot be undone.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel", style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null) {
      return const Scaffold(backgroundColor: Color(0xFF020408), body: Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF020408),
      body: Stack(
        children: [
          const BackgroundCanvas(),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('applications').orderBy('appliedAt', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
              if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));

              final docs = snapshot.data!.docs;
              final bool isAllSelected = docs.isNotEmpty && _selectedIds.length == docs.length;

              return Column(
                children: [
                  AdminNavbar(
                    selectedCount: _selectedIds.length,
                    totalDocs: docs.length,
                    isAllSelected: isAllSelected,
                    onSelectAll: () => _toggleSelectAll(docs),
                    onDeleteSelected: _deleteSelectedRecords,
                    onLogout: () async {
                      await FirebaseAuth.instance.signOut();
                      if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                    }
                  ),
                  Expanded(
                    child: docs.isEmpty 
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_outlined, size: 60, color: Colors.white.withValues(alpha: 0.2)),
                            const SizedBox(height: 20),
                            const Text("No applications received yet.", style: TextStyle(color: Colors.white54)),
                          ],
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          int crossAxisCount = constraints.maxWidth > 1100 ? 3 : (constraints.maxWidth > 700 ? 2 : 1);
                          return GridView.builder(
                            padding: const EdgeInsets.all(30),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 25,
                              mainAxisSpacing: 25,
                              // ADJUSTED TO GIVE MORE HEIGHT FOR THE PAYMENTS BUTTON
                              childAspectRatio: 0.74, 
                            ),
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final doc = docs[index];
                              final data = doc.data() as Map<String, dynamic>;
                              final docId = doc.id;
                              final isSelected = _selectedIds.contains(docId);

                              return ApplicationCard(
                                data: data,
                                docId: docId,
                                isSelected: isSelected,
                                onSelect: () => _toggleSelection(docId),
                                onDelete: () => _deleteRecord(docId),
                                onVerify: () => _verifyUser(
                                  docId,
                                  (data['status'] ?? 'pending') as String,
                                  '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim(),
                                  (data['email'] ?? 'No Email') as String,
                                ),
                                onGradeExam: () => _gradeExam(
                                  docId,
                                  '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim(),
                                  (data['email'] ?? 'No Email') as String,
                                  (data['onboardingExam'] as Map<String, dynamic>?)?['status'] as String? ?? 'pending_review',
                                ),
                              );
                            },
                          );
                        },
                      ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}