import 'dart:ui';
import 'dart:math' as math;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html; // REQUIRED FOR WEB ACTIONS
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ===========================================================================
// DATATRICKS AI - ADMIN DASHBOARD (WEB OPTIMIZED)
// ===========================================================================

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with TickerProviderStateMixin {
  
  // SELECTION STATE
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  /// SECURITY CHECK: Redirects to login if no user is found
  void _checkAuth() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null && mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    });
  }

  // TOGGLE SELECTION FOR SINGLE ITEM
  void _toggleSelection(String docId) {
    setState(() {
      if (_selectedIds.contains(docId)) {
        _selectedIds.remove(docId);
      } else {
        _selectedIds.add(docId);
      }
    });
  }

  // TOGGLE SELECT ALL
  void _toggleSelectAll(List<QueryDocumentSnapshot> docs) {
    setState(() {
      if (_selectedIds.length == docs.length && docs.isNotEmpty) {
        // If all are currently selected, deselect all
        _selectedIds.clear();
      } else {
        // Otherwise, select all
        _selectedIds.clear();
        for (var doc in docs) {
          _selectedIds.add(doc.id);
        }
      }
    });
  }

  // VERIFY / UNVERIFY A USER  — shows confirmation popup first
  Future<void> _verifyUser(
    String docId,
    String currentStatus,
    String fullName,
    String email,
  ) async {
    final newStatus = currentStatus == 'approved' ? 'pending' : 'approved';
    final isApproving = newStatus == 'approved';

    // Show confirmation popup — wait for admin's decision
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (ctx) => _VerifyConfirmDialog(
        fullName: fullName,
        email: email,
        isApproving: isApproving,
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await FirebaseFirestore.instance
          .collection('applications')
          .doc(docId)
          .update({
        'status': newStatus,
        'verifiedAt': isApproving
            ? FieldValue.serverTimestamp()
            : FieldValue.delete(),
        'verifiedBy': isApproving
            ? FirebaseAuth.instance.currentUser?.uid
            : FieldValue.delete(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            Icon(
              isApproving ? Icons.verified_rounded : Icons.undo_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(
              isApproving
                  ? '$fullName has been verified'
                  : '$fullName has been set back to pending',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ]),
          backgroundColor:
              isApproving ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(20),
          duration: const Duration(seconds: 4),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
  }

  // GRADE EXAM — shows Pass/Fail popup then writes to Firestore
  Future<void> _gradeExam(
    String docId,
    String fullName,
    String email,
    String currentExamStatus,
  ) async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => _ExamGradeDialog(
        fullName: fullName,
        email: email,
        currentExamStatus: currentExamStatus,
      ),
    );

    if (result == null || !mounted) return;

    try {
      await FirebaseFirestore.instance
          .collection('applications')
          .doc(docId)
          .update({
        'onboardingExam.status'   : result,
        'onboardingExam.gradedAt' : FieldValue.serverTimestamp(),
        'onboardingExam.gradedBy' : FirebaseAuth.instance.currentUser?.uid,
      });

      if (mounted) {
        final passed = result == 'passed';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            Icon(
              passed ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(
              passed
                  ? '$fullName marked as PASSED'
                  : '$fullName marked as FAILED',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error grading exam: $e'),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
  }

  // DELETE SINGLE RECORD
  Future<void> _deleteRecord(String docId) async {
    bool confirm = await _showDeleteConfirmDialog("Delete this application?");
    if (confirm) {
      await FirebaseFirestore.instance.collection('applications').doc(docId).delete();
      if (mounted) {
        setState(() {
          _selectedIds.remove(docId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Record deleted"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  // DELETE SELECTED RECORDS
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
        setState(() {
          _selectedIds.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Selected records deleted"), backgroundColor: Colors.redAccent),
        );
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
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF020408),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF020408),
      body: Stack(
        children: [
          // Background Painter
          const _BackgroundCanvas(),

          // MAIN CONTENT WRAPPED IN STREAM BUILDER
          // Moving this up allows the Navbar to know about the data for "Select All"
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('applications')
                .orderBy('appliedAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              // LOADING STATE
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
              }

              // ERROR STATE
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
              }

              final docs = snapshot.data!.docs;
              final bool isAllSelected = docs.isNotEmpty && _selectedIds.length == docs.length;

              return Column(
                children: [
                  // NAVBAR (Now has access to docs for Select All logic)
                  _AdminNavbar(
                    selectedCount: _selectedIds.length,
                    totalDocs: docs.length,
                    isAllSelected: isAllSelected,
                    onSelectAll: () => _toggleSelectAll(docs),
                    onDeleteSelected: _deleteSelectedRecords,
                    onLogout: () async {
                      await FirebaseAuth.instance.signOut();
                      if (mounted) {
                        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                      }
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
                              childAspectRatio: 0.85, 
                            ),
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final doc = docs[index];
                              final data = doc.data() as Map<String, dynamic>;
                              final docId = doc.id;
                              final isSelected = _selectedIds.contains(docId);

                              return _ApplicationCard(
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

// ===========================================================================
// ADMIN NAVBAR (UPDATED)
// ===========================================================================

class _AdminNavbar extends StatelessWidget {
  final VoidCallback onLogout;
  final VoidCallback onDeleteSelected;
  final VoidCallback onSelectAll;
  final int selectedCount;
  final int totalDocs;
  final bool isAllSelected;

  const _AdminNavbar({
    required this.onLogout,
    required this.onDeleteSelected,
    required this.onSelectAll,
    required this.selectedCount,
    required this.totalDocs,
    required this.isAllSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 90, 
          padding: const EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
            color: Colors.black.withValues(alpha: 0.4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // LEFT: LOGO
              Row(
                children: [
                  Stack(
                    alignment: Alignment.bottomCenter,
                    clipBehavior: Clip.none,
                    children: [
                      const Positioned(
                        bottom: 5,
                        child: _SmokeEffect(width: 60, height: 80),
                      ),
                      Image.asset(
                        'assets/images/logo.png',
                        height: 45,
                        errorBuilder: (c,e,s) => const Icon(Icons.rocket_launch, color: Colors.white, size: 40),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "DATATRICKS AI", 
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: -0.5)
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1),
                          borderRadius: BorderRadius.circular(4)
                        ),
                        child: const Text("ADMIN ACCESS", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      ),
                    ],
                  ),
                ],
              ),

              // RIGHT: ACTIONS
              Row(
                children: [
                  // SELECT ALL BUTTON (Visible if there are docs)
                  if (totalDocs > 0) ...[
                    InkWell(
                      onTap: onSelectAll,
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: isAllSelected ? const Color(0xFF6366F1).withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: isAllSelected ? const Color(0xFF6366F1) : Colors.white.withValues(alpha: 0.2)
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isAllSelected ? Icons.check_box : Icons.check_box_outline_blank, 
                              color: isAllSelected ? const Color(0xFF6366F1) : Colors.white70, 
                              size: 20
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isAllSelected ? "Deselect All" : "Select All", 
                              style: TextStyle(
                                color: isAllSelected ? const Color(0xFF6366F1) : Colors.white70, 
                                fontWeight: FontWeight.bold, 
                                fontSize: 14
                              )
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                  ],

                  // DELETE SELECTED BUTTON (Visible only if items selected)
                  if (selectedCount > 0) ...[
                    InkWell(
                      onTap: onDeleteSelected,
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              "Delete ($selectedCount)", 
                              style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14)
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                  ],

                  // LOGOUT BUTTON
                  InkWell(
                    onTap: onLogout,
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                        boxShadow: [
                          BoxShadow(color: Colors.redAccent.withValues(alpha: 0.1), blurRadius: 10, spreadRadius: -2)
                        ],
                      ),
                      child: Row(
                        children: const [
                          Text("Log Out", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                          SizedBox(width: 10),
                          Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// ANIMATION LOGIC (UNCHANGED)
// ===========================================================================

class _SmokeEffect extends StatefulWidget {
  final double width;
  final double height;
  const _SmokeEffect({required this.width, required this.height});

  @override
  State<_SmokeEffect> createState() => _SmokeEffectState();
}

class _SmokeEffectState extends State<_SmokeEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_SmokeParticle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _controller.addListener(_updateParticles);
  }

  void _updateParticles() {
    if (_random.nextDouble() < 0.15) { 
      _particles.add(_SmokeParticle(
        x: widget.width / 2 + (_random.nextDouble() * 20 - 10),
        y: widget.height, 
        size: _random.nextDouble() * 5 + 2,
        speed: _random.nextDouble() * 1.5 + 0.5,
        color: _random.nextBool() ? const Color(0xFF6366F1) : const Color(0xFFEC4899),
      ));
    }
    for (var particle in _particles) {
      particle.y -= particle.speed;
      particle.x += (_random.nextDouble() * 1.0 - 0.5); 
      particle.life -= 0.015;
      particle.size += 0.03; 
    }
    _particles.removeWhere((p) => p.life <= 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => CustomPaint(
        size: Size(widget.width, widget.height),
        painter: _SmokePainter(_particles),
      ),
    );
  }
}

class _SmokeParticle {
  double x, y, size, speed, life = 1.0;
  Color color;
  _SmokeParticle({required this.x, required this.y, required this.size, required this.speed, required this.color});
}

class _SmokePainter extends CustomPainter {
  final List<_SmokeParticle> particles;
  _SmokePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      final paint = Paint()
        ..color = p.color.withValues(alpha: p.life * 0.4) 
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0); 
      canvas.drawCircle(Offset(p.x, p.y), p.size, paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ===========================================================================
// APPLICATION CARD WIDGET
// ===========================================================================

class _ApplicationCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onDelete;
  final VoidCallback onVerify;
  final VoidCallback onGradeExam;

  const _ApplicationCard({
    required this.data, 
    required this.docId,
    required this.isSelected,
    required this.onSelect,
    required this.onDelete,
    required this.onVerify,
    required this.onGradeExam,
  });

  // ---------------------------------------------------------------------------
  // VIEW IN NEW TAB
  // ---------------------------------------------------------------------------
  void _viewDoc(BuildContext context, String? url) {
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No document link found."), backgroundColor: Colors.redAccent),
      );
      return;
    }

    try {
      final html.AnchorElement anchor = html.AnchorElement(href: url);
      anchor.target = "_blank";
      anchor.click();
    } catch (e) {
      debugPrint("View error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error opening document."), backgroundColor: Colors.redAccent),
      );
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "Date Unknown";
    DateTime d = timestamp.toDate();
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    String hour = d.hour > 12 ? (d.hour - 12).toString() : (d.hour == 0 ? "12" : d.hour.toString());
    String amPm = d.hour >= 12 ? "PM" : "AM";
    String minute = d.minute.toString().padLeft(2, '0');
    return "${months[d.month - 1]} ${d.day}, ${d.year} • $hour:$minute $amPm";
  }

  @override
  Widget build(BuildContext context) {
    final String fullName = "${data['firstName'] ?? ''} ${data['lastName'] ?? ''}";
    final String role = data['role'] ?? 'Unknown Role';
    final String email = data['email'] ?? 'No Email';
    final String phone = data['phone'] ?? 'No Phone';
    final String highSchool = data['highSchool'] ?? 'N/A';
    final String location = "${data['location']?['city'] ?? ''}, ${data['location']?['state'] ?? ''}";
    final String source = data['source'] ?? 'Unknown';
    final String resumeUrl = data['resumeUrl'] ?? '';
    final String suppUrl = data['suppDocUrl'] ?? '';
    final String date = _formatTimestamp(data['appliedAt']);
    final String status = data['status'] ?? 'pending';
    final bool isApproved = status == 'approved';

    // Exam data
    final Map<String, dynamic>? examData = data['onboardingExam'] as Map<String, dynamic>?;
    final String examStatus = examData?['status'] as String? ?? '';
    final bool hasExam = examStatus.isNotEmpty;
    final bool examPassed  = examStatus == 'passed';
    final bool examFailed  = examStatus == 'failed';

    return Container(
      decoration: BoxDecoration(
        color: isSelected 
            ? const Color(0xFF6366F1).withValues(alpha: 0.15) // Highlight if selected
            : const Color(0xFF0F172A).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isSelected ? const Color(0xFF6366F1) : Colors.white.withValues(alpha: 0.08),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // CARD HEADER: Checkbox - Role - Status - Delete
                Row(
                  children: [
                    // CHECKBOX (Custom Selection Circle)
                    InkWell(
                      onTap: onSelect,
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        width: 20, height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
                          border: Border.all(
                            color: isSelected ? const Color(0xFF6366F1) : Colors.white54, 
                            width: 2
                          ),
                        ),
                        child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                      ),
                    ),

                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          role.toUpperCase(), 
                          style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5), 
                          overflow: TextOverflow.ellipsis
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // LIVE STATUS CHIP
                    _StatusBadge(status: status),
                    const SizedBox(width: 8),
                    // INDIVIDUAL DELETE ICON
                    InkWell(
                      onTap: onDelete,
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(Icons.delete_outline_rounded, color: Colors.white24, size: 20),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 15),
                Text(fullName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(date, style: const TextStyle(color: Colors.white38, fontSize: 13)),
                
                const SizedBox(height: 20),
                Divider(color: Colors.white.withValues(alpha: 0.05)),
                const SizedBox(height: 20),

                // DETAILS
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _InfoRow(icon: Icons.email_outlined, text: email),
                        const SizedBox(height: 12),
                        _InfoRow(icon: Icons.phone_outlined, text: phone),
                        const SizedBox(height: 12),
                        _InfoRow(icon: Icons.location_on_outlined, text: location),
                        const SizedBox(height: 12),
                        _InfoRow(icon: Icons.school_outlined, text: highSchool),
                        const SizedBox(height: 12),
                        _InfoRow(icon: Icons.campaign_outlined, text: "Found via: $source"),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // VERIFICATION BUTTON
                const Text("VERIFICATION", style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                const SizedBox(height: 10),
                InkWell(
                  onTap: onVerify,
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: isApproved
                          ? const Color(0xFF10B981).withValues(alpha: 0.12)
                          : const Color(0xFF6366F1).withValues(alpha: 0.10),
                      border: Border.all(
                        color: isApproved
                            ? const Color(0xFF10B981).withValues(alpha: 0.5)
                            : const Color(0xFF6366F1).withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isApproved ? Icons.verified_rounded : Icons.verified_outlined,
                          color: isApproved ? const Color(0xFF10B981) : const Color(0xFF818CF8),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isApproved ? 'Verified  ·  Tap to Revoke' : 'Tap to Verify User',
                          style: TextStyle(
                            color: isApproved ? const Color(0xFF10B981) : const Color(0xFF818CF8),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                
                // ── EXAM GRADING ─────────────────────────────────────────
                if (hasExam) ...[
                  const Text("EXAM RESULT", style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: onGradeExam,
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
                      decoration: BoxDecoration(
                        color: examPassed
                            ? const Color(0xFF10B981).withValues(alpha: 0.10)
                            : examFailed
                                ? const Color(0xFFEF4444).withValues(alpha: 0.10)
                                : const Color(0xFFF59E0B).withValues(alpha: 0.10),
                        border: Border.all(
                          color: examPassed
                              ? const Color(0xFF10B981).withValues(alpha: 0.45)
                              : examFailed
                                  ? const Color(0xFFEF4444).withValues(alpha: 0.45)
                                  : const Color(0xFFF59E0B).withValues(alpha: 0.45),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            examPassed
                                ? Icons.check_circle_rounded
                                : examFailed
                                    ? Icons.cancel_rounded
                                    : Icons.pending_actions_rounded,
                            color: examPassed
                                ? const Color(0xFF10B981)
                                : examFailed
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFFF59E0B),
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              examPassed
                                  ? 'Exam Passed  ·  Tap to Re-grade'
                                  : examFailed
                                      ? 'Exam Failed  ·  Tap to Re-grade'
                                      : 'Pending Review  ·  Tap to Grade',
                              style: TextStyle(
                                color: examPassed
                                    ? const Color(0xFF10B981)
                                    : examFailed
                                        ? const Color(0xFFEF4444)
                                        : const Color(0xFFF59E0B),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.edit_rounded,
                            color: examPassed
                                ? const Color(0xFF10B981).withValues(alpha: 0.6)
                                : examFailed
                                    ? const Color(0xFFEF4444).withValues(alpha: 0.6)
                                    : const Color(0xFFF59E0B).withValues(alpha: 0.6),
                            size: 15,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // DOCUMENTS ACTIONS
                const Text("ATTACHMENTS", style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: _DocButton(
                        label: "View Resume", 
                        icon: Icons.visibility_rounded, 
                        color: const Color(0xFFEC4899), 
                        onTap: () => _viewDoc(context, resumeUrl),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DocButton(
                        label: "View Transcripts", 
                        icon: Icons.visibility_rounded, 
                        color: Colors.cyanAccent, 
                        onTap: () => _viewDoc(context, suppUrl),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// VERIFY CONFIRMATION DIALOG
// ===========================================================================

class _VerifyConfirmDialog extends StatefulWidget {
  final String fullName;
  final String email;
  final bool isApproving;

  const _VerifyConfirmDialog({
    required this.fullName,
    required this.email,
    required this.isApproving,
  });

  @override
  State<_VerifyConfirmDialog> createState() => _VerifyConfirmDialogState();
}

class _VerifyConfirmDialogState extends State<_VerifyConfirmDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    )..forward();
    _scale = CurvedAnimation(parent: _anim, curve: Curves.easeOutBack);
    _fade  = CurvedAnimation(parent: _anim, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isApproving = widget.isApproving;
    final accentColor =
        isApproving ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    final headerTop =
        isApproving ? const Color(0xFF0D2E22) : const Color(0xFF2E1F0A);
    final headerBot =
        isApproving ? const Color(0xFF0A1F18) : const Color(0xFF1C1205);

    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 420,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.35),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.20),
                    blurRadius: 50,
                    spreadRadius: 2,
                    offset: const Offset(0, 16),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 30,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── HEADER ──────────────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 36),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [headerTop, headerBot],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Column(children: [
                        // Icon rings
                        Stack(alignment: Alignment.center, children: [
                          Container(
                            width: 90, height: 90,
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 68, height: 68,
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 50, height: 50,
                            decoration: BoxDecoration(
                              color: accentColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withValues(alpha: 0.5),
                                  blurRadius: 18,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Icon(
                              isApproving
                                  ? Icons.verified_user_rounded
                                  : Icons.remove_moderator_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        ]),
                        const SizedBox(height: 18),
                        Text(
                          isApproving
                              ? 'Confirm Verification'
                              : 'Revoke Verification',
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isApproving
                              ? 'You are about to approve this user'
                              : 'You are about to revoke this user\'s access',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 13,
                          ),
                        ),
                      ]),
                    ),

                    // ── BODY ────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
                      child: Column(children: [
                        // User info card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Label
                              Text(
                                'USER TO BE ${isApproving ? 'VERIFIED' : 'REVOKED'}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.4,
                                ),
                              ),
                              const SizedBox(height: 14),
                              // Avatar + name row
                              Row(children: [
                                Container(
                                  width: 44, height: 44,
                                  decoration: BoxDecoration(
                                    color: accentColor.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: accentColor.withValues(alpha: 0.4),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      widget.fullName.isNotEmpty
                                          ? widget.fullName[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        color: accentColor,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.fullName.isEmpty
                                            ? 'Unknown User'
                                            : widget.fullName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(children: [
                                        Icon(
                                          Icons.email_outlined,
                                          size: 13,
                                          color: Colors.white.withValues(alpha: 0.4),
                                        ),
                                        const SizedBox(width: 5),
                                        Expanded(
                                          child: Text(
                                            widget.email,
                                            style: TextStyle(
                                              color: Colors.white.withValues(alpha: 0.55),
                                              fontSize: 13,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ]),
                                    ],
                                  ),
                                ),
                              ]),
                              const SizedBox(height: 16),
                              // Status change indicator
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 14),
                                decoration: BoxDecoration(
                                  color: accentColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: accentColor.withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _StatusPill(
                                      label: isApproving ? 'Pending' : 'Verified',
                                      color: isApproving
                                          ? const Color(0xFFF59E0B)
                                          : const Color(0xFF10B981),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      child: Icon(
                                        Icons.arrow_forward_rounded,
                                        color: Colors.white.withValues(alpha: 0.3),
                                        size: 16,
                                      ),
                                    ),
                                    _StatusPill(
                                      label: isApproving ? 'Verified' : 'Pending',
                                      color: isApproving
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFF59E0B),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Warning note
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.07),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 15,
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  isApproving
                                      ? 'This will grant the user full access to the platform. They will be notified of their approved status.'
                                      : 'This will remove the user\'s verified status and set them back to pending review.',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    fontSize: 12,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── ACTION BUTTONS ───────────────────────────
                        Row(children: [
                          // Cancel
                          Expanded(
                            child: InkWell(
                              onTap: () => Navigator.of(context).pop(false),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.1),
                                  ),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Confirm
                          Expanded(
                            flex: 2,
                            child: InkWell(
                              onTap: () => Navigator.of(context).pop(true),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                decoration: BoxDecoration(
                                  color: accentColor,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: accentColor.withValues(alpha: 0.4),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      isApproving
                                          ? Icons.verified_rounded
                                          : Icons.remove_moderator_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isApproving
                                          ? 'Yes, Verify User'
                                          : 'Yes, Revoke Access',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ]),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// EXAM GRADE DIALOG  — Pass / Fail
// ===========================================================================

class _ExamGradeDialog extends StatefulWidget {
  final String fullName;
  final String email;
  final String currentExamStatus;

  const _ExamGradeDialog({
    required this.fullName,
    required this.email,
    required this.currentExamStatus,
  });

  @override
  State<_ExamGradeDialog> createState() => _ExamGradeDialogState();
}

class _ExamGradeDialogState extends State<_ExamGradeDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _scale;
  late Animation<double> _fade;

  String? _selected; // 'passed' or 'failed'

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    )..forward();
    _scale = CurvedAnimation(parent: _anim, curve: Curves.easeOutBack);
    _fade  = CurvedAnimation(parent: _anim, curve: Curves.easeIn);

    // Pre-select current grade if already graded
    if (widget.currentExamStatus == 'passed' || widget.currentExamStatus == 'failed') {
      _selected = widget.currentExamStatus;
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool canConfirm = _selected != null;

    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 440,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.18),
                    blurRadius: 50,
                    spreadRadius: 2,
                    offset: const Offset(0, 16),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 30,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    // ── HEADER ────────────────────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1E1B4B), Color(0xFF0F0E2A)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Column(children: [
                        Stack(alignment: Alignment.center, children: [
                          Container(
                            width: 88, height: 88,
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 66, height: 66,
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 50, height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6366F1).withValues(alpha: 0.50),
                                  blurRadius: 18,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.fact_check_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        ]),
                        const SizedBox(height: 18),
                        const Text(
                          'Grade Exam',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Select a result for this applicant\'s exam',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.40),
                            fontSize: 13,
                          ),
                        ),
                      ]),
                    ),

                    // ── BODY ──────────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
                      child: Column(
                        children: [

                          // Applicant info card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                            ),
                            child: Row(children: [
                              Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    widget.fullName.isNotEmpty ? widget.fullName[0].toUpperCase() : '?',
                                    style: const TextStyle(
                                      color: Color(0xFF818CF8),
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(
                                    widget.fullName.isEmpty ? 'Unknown User' : widget.fullName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Row(children: [
                                    Icon(Icons.email_outlined, size: 12, color: Colors.white.withValues(alpha: 0.35)),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: Text(
                                        widget.email,
                                        style: TextStyle(color: Colors.white.withValues(alpha: 0.50), fontSize: 12),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ]),
                                ]),
                              ),
                            ]),
                          ),

                          const SizedBox(height: 20),

                          // ── PASS / FAIL CHOICE ────────────────────────
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'SELECT RESULT',
                              style: TextStyle(
                                color: Colors.white30,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          Row(children: [
                            // PASS button
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _selected = 'passed'),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  decoration: BoxDecoration(
                                    color: _selected == 'passed'
                                        ? const Color(0xFF10B981).withValues(alpha: 0.18)
                                        : Colors.white.withValues(alpha: 0.03),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _selected == 'passed'
                                          ? const Color(0xFF10B981)
                                          : Colors.white.withValues(alpha: 0.10),
                                      width: _selected == 'passed' ? 2.0 : 1.0,
                                    ),
                                    boxShadow: _selected == 'passed'
                                        ? [BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 4))]
                                        : [],
                                  ),
                                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                    Container(
                                      width: 46, height: 46,
                                      decoration: BoxDecoration(
                                        color: _selected == 'passed'
                                            ? const Color(0xFF10B981).withValues(alpha: 0.20)
                                            : Colors.white.withValues(alpha: 0.05),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.check_circle_rounded,
                                        color: _selected == 'passed'
                                            ? const Color(0xFF10B981)
                                            : Colors.white24,
                                        size: 26,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'PASSED',
                                      style: TextStyle(
                                        color: _selected == 'passed'
                                            ? const Color(0xFF10B981)
                                            : Colors.white38,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Applicant qualifies',
                                      style: TextStyle(
                                        color: _selected == 'passed'
                                            ? const Color(0xFF10B981).withValues(alpha: 0.70)
                                            : Colors.white24,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ]),
                                ),
                              ),
                            ),

                            const SizedBox(width: 14),

                            // FAIL button
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _selected = 'failed'),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  decoration: BoxDecoration(
                                    color: _selected == 'failed'
                                        ? const Color(0xFFEF4444).withValues(alpha: 0.18)
                                        : Colors.white.withValues(alpha: 0.03),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _selected == 'failed'
                                          ? const Color(0xFFEF4444)
                                          : Colors.white.withValues(alpha: 0.10),
                                      width: _selected == 'failed' ? 2.0 : 1.0,
                                    ),
                                    boxShadow: _selected == 'failed'
                                        ? [BoxShadow(color: const Color(0xFFEF4444).withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 4))]
                                        : [],
                                  ),
                                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                    Container(
                                      width: 46, height: 46,
                                      decoration: BoxDecoration(
                                        color: _selected == 'failed'
                                            ? const Color(0xFFEF4444).withValues(alpha: 0.20)
                                            : Colors.white.withValues(alpha: 0.05),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.cancel_rounded,
                                        color: _selected == 'failed'
                                            ? const Color(0xFFEF4444)
                                            : Colors.white24,
                                        size: 26,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'FAILED',
                                      style: TextStyle(
                                        color: _selected == 'failed'
                                            ? const Color(0xFFEF4444)
                                            : Colors.white38,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Does not qualify',
                                      style: TextStyle(
                                        color: _selected == 'failed'
                                            ? const Color(0xFFEF4444).withValues(alpha: 0.70)
                                            : Colors.white24,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ]),
                                ),
                              ),
                            ),
                          ]),

                          const SizedBox(height: 20),

                          // Info note
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.info_outline_rounded, size: 15, color: Colors.white.withValues(alpha: 0.30)),
                                const SizedBox(width: 9),
                                Expanded(
                                  child: Text(
                                    'This result will be stored under onboardingExam.status in Firestore. '
                                    'The applicant\'s app will reflect this result immediately.',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.38),
                                      fontSize: 12,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // ── ACTION BUTTONS ───────────────────────────
                          Row(children: [
                            // Cancel
                            Expanded(
                              child: InkWell(
                                onTap: () => Navigator.of(context).pop(null),
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Confirm
                            Expanded(
                              flex: 2,
                              child: InkWell(
                                onTap: canConfirm ? () => Navigator.of(context).pop(_selected) : null,
                                borderRadius: BorderRadius.circular(14),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  decoration: BoxDecoration(
                                    color: canConfirm
                                        ? (_selected == 'passed'
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFFEF4444))
                                        : Colors.white.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: canConfirm
                                        ? [
                                            BoxShadow(
                                              color: (_selected == 'passed'
                                                  ? const Color(0xFF10B981)
                                                  : const Color(0xFFEF4444))
                                                  .withValues(alpha: 0.40),
                                              blurRadius: 16,
                                              offset: const Offset(0, 4),
                                            ),
                                          ]
                                        : [],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _selected == 'passed'
                                            ? Icons.check_circle_rounded
                                            : _selected == 'failed'
                                                ? Icons.cancel_rounded
                                                : Icons.fact_check_rounded,
                                        color: canConfirm ? Colors.white : Colors.white24,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        canConfirm
                                            ? (_selected == 'passed' ? 'Confirm Pass' : 'Confirm Fail')
                                            : 'Select a Result',
                                        style: TextStyle(
                                          color: canConfirm ? Colors.white : Colors.white24,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Small pill used inside the status-change indicator
class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 6, height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ]),
    );
  }
}

// ===========================================================================
// INFO ROW
// ===========================================================================

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white54),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

// ===========================================================================
// STATUS BADGE  (shown in card header)
// ===========================================================================

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (Color color, String label) = switch (status) {
      'approved'  => (const Color(0xFF10B981), 'Verified'),
      'reviewing' => (const Color(0xFF3B82F6), 'Reviewing'),
      'rejected'  => (const Color(0xFFEF4444), 'Rejected'),
      _           => (const Color(0xFFF59E0B), 'Pending'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _DocButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DocButton({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// BACKGROUND PAINTER
// ===========================================================================

class _BackgroundCanvas extends StatelessWidget {
  const _BackgroundCanvas();
  @override
  Widget build(BuildContext context) => Positioned.fill(child: CustomPaint(painter: _BgPainter()));
}

class _BgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF020408);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);
    final gridPaint = Paint()..color = Colors.white.withValues(alpha: 0.02)..strokeWidth = 1;
    for (double i = 0; i < size.width; i += 60) canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    for (double i = 0; i < size.height; i += 60) canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}