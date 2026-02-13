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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.white.withOpacity(0.1))),
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
                            Icon(Icons.inbox_outlined, size: 60, color: Colors.white.withOpacity(0.2)),
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
            border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08))),
            color: Colors.black.withOpacity(0.4),
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
                          color: isAllSelected ? const Color(0xFF6366F1).withOpacity(0.1) : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: isAllSelected ? const Color(0xFF6366F1) : Colors.white.withOpacity(0.2)
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
                          color: Colors.redAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
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
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                        boxShadow: [
                          BoxShadow(color: Colors.redAccent.withOpacity(0.1), blurRadius: 10, spreadRadius: -2)
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
        ..color = p.color.withOpacity(p.life * 0.4) 
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

  const _ApplicationCard({
    required this.data, 
    required this.docId,
    required this.isSelected,
    required this.onSelect,
    required this.onDelete,
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

    return Container(
      decoration: BoxDecoration(
        color: isSelected 
            ? const Color(0xFF6366F1).withOpacity(0.15) // Highlight if selected
            : const Color(0xFF0F172A).withOpacity(0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isSelected ? const Color(0xFF6366F1) : Colors.white.withOpacity(0.08),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))
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
                        decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          role.toUpperCase(), 
                          style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5), 
                          overflow: TextOverflow.ellipsis
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 8, width: 8, 
                      decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.greenAccent, blurRadius: 5)])
                    ),
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
                Divider(color: Colors.white.withOpacity(0.05)),
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
          color: color.withOpacity(0.08),
          border: Border.all(color: color.withOpacity(0.2)),
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
    final gridPaint = Paint()..color = Colors.white.withOpacity(0.02)..strokeWidth = 1;
    for (double i = 0; i < size.width; i += 60) canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    for (double i = 0; i < size.height; i += 60) canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}