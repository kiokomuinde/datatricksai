import 'dart:ui';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Important: Ensure this path correctly points to your payments screen file
import '../admin_payments_screen.dart'; 

class ApplicationCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onDelete;
  final VoidCallback onVerify;
  final VoidCallback onGradeExam;

  const ApplicationCard({
    super.key,
    required this.data, 
    required this.docId,
    required this.isSelected,
    required this.onSelect,
    required this.onDelete,
    required this.onVerify,
    required this.onGradeExam,
  });

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

    final Map<String, dynamic>? examData = data['onboardingExam'] as Map<String, dynamic>?;
    final String examStatus = examData?['status'] as String? ?? '';
    final bool hasExam = examStatus.isNotEmpty;
    final bool examPassed  = examStatus == 'passed';
    final bool examFailed  = examStatus == 'failed';

    final Map<String, dynamic>? paymentData = data['paymentInfo'] as Map<String, dynamic>?;
    final bool hasPayment = paymentData != null;

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF6366F1).withValues(alpha: 0.15) : const Color(0xFF0F172A).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isSelected ? const Color(0xFF6366F1) : Colors.white.withValues(alpha: 0.08),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))],
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
                Row(
                  children: [
                    InkWell(
                      onTap: onSelect,
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        width: 20, height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
                          border: Border.all(color: isSelected ? const Color(0xFF6366F1) : Colors.white54, width: 2),
                        ),
                        child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                        child: Text(role.toUpperCase(), style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5), overflow: TextOverflow.ellipsis),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusBadge(status: status),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: onDelete,
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(padding: EdgeInsets.all(4.0), child: Icon(Icons.delete_outline_rounded, color: Colors.white24, size: 20)),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Text(fullName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(date, style: const TextStyle(color: Colors.white38, fontSize: 13)),
                const SizedBox(height: 20),
                Divider(color: Colors.white.withValues(alpha: 0.05)),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                        
                        const SizedBox(height: 20),
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
                              color: isApproved ? const Color(0xFF10B981).withValues(alpha: 0.12) : const Color(0xFF6366F1).withValues(alpha: 0.10),
                              border: Border.all(color: isApproved ? const Color(0xFF10B981).withValues(alpha: 0.5) : const Color(0xFF6366F1).withValues(alpha: 0.4), width: 1.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(isApproved ? Icons.verified_rounded : Icons.verified_outlined, color: isApproved ? const Color(0xFF10B981) : const Color(0xFF818CF8), size: 18),
                                const SizedBox(width: 8),
                                Text(isApproved ? 'Verified  ·  Tap to Revoke' : 'Tap to Verify User', style: TextStyle(color: isApproved ? const Color(0xFF10B981) : const Color(0xFF818CF8), fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.3)),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
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
                                color: examPassed ? const Color(0xFF10B981).withValues(alpha: 0.10) : examFailed ? const Color(0xFFEF4444).withValues(alpha: 0.10) : const Color(0xFFF59E0B).withValues(alpha: 0.10),
                                border: Border.all(color: examPassed ? const Color(0xFF10B981).withValues(alpha: 0.45) : examFailed ? const Color(0xFFEF4444).withValues(alpha: 0.45) : const Color(0xFFF59E0B).withValues(alpha: 0.45), width: 1.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(examPassed ? Icons.check_circle_rounded : examFailed ? Icons.cancel_rounded : Icons.pending_actions_rounded, color: examPassed ? const Color(0xFF10B981) : examFailed ? const Color(0xFFEF4444) : const Color(0xFFF59E0B), size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(examPassed ? 'Exam Passed  ·  Tap to Re-grade' : examFailed ? 'Exam Failed  ·  Tap to Re-grade' : 'Pending Review  ·  Tap to Grade',
                                      style: TextStyle(color: examPassed ? const Color(0xFF10B981) : examFailed ? const Color(0xFFEF4444) : const Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.3),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        
                        const Text("FINANCIAL & IDENTITY", style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: hasPayment ? () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => AdminPaymentsScreen(uid: docId)));
                          } : null,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: hasPayment ? const Color(0xFF6366F1).withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.02),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: hasPayment ? const Color(0xFF6366F1).withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(hasPayment ? Icons.payments_rounded : Icons.money_off_rounded, color: hasPayment ? const Color(0xFF818CF8) : Colors.white24, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  hasPayment ? "View Secure Payment Data" : "No Payment Info",
                                  style: TextStyle(color: hasPayment ? const Color(0xFF818CF8) : Colors.white38, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        const Text("ATTACHMENTS", style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                        const SizedBox(height: 12),
                        _DocumentTile(label: "Applicant Resume", url: resumeUrl, color: const Color(0xFFEC4899)),
                        const SizedBox(height: 10),
                        _DocumentTile(label: "Supporting Transcripts", url: suppUrl, color: Colors.cyanAccent),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── NEW DOCUMENT TILE COMPONENT ─────────────────────────────────────────────────────────

class _DocumentTile extends StatelessWidget {
  final String label;
  final String? url;
  final Color color;

  const _DocumentTile({required this.label, required this.url, required this.color});

  void _handleAction(BuildContext context, bool isDownload) {
    if (url == null || url!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Document link not found."), backgroundColor: Colors.redAccent));
      return;
    }

    String finalUrl = url!;

    try {
      if (isDownload) {
        // If the URL is hosted on Cloudinary, force the server to attach it as a downloadable file
        // instead of opening it in the browser window.
        if (finalUrl.contains('cloudinary.com') && !finalUrl.contains('fl_attachment')) {
          final parts = finalUrl.split('upload/');
          if (parts.length == 2) {
            final safeName = label.replaceAll(' ', '_');
            finalUrl = '${parts[0]}upload/fl_attachment:$safeName/${parts[1]}';
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Initiating download for $label..."),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 2),
        ));
      }

      final html.AnchorElement anchor = html.AnchorElement(href: finalUrl);
      
      // Fallback HTML5 download attribute for non-Cloudinary links
      if (isDownload) {
        anchor.setAttribute("download", "${label.replaceAll(' ', '_')}.pdf");
      }
      
      anchor.target = "_blank";
      anchor.click();

    } catch (e) {
      debugPrint("Document action error: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error accessing document."), backgroundColor: Colors.redAccent));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.description_rounded, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          ),
          
          // View Button
          InkWell(
            onTap: () => _handleAction(context, false),
            borderRadius: BorderRadius.circular(8),
            child: Tooltip(
              message: "View Document",
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: Icon(Icons.visibility_rounded, color: color.withValues(alpha: 0.8), size: 20),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Download Button
          InkWell(
            onTap: () => _handleAction(context, true),
            borderRadius: BorderRadius.circular(8),
            child: Tooltip(
              message: "Download File",
              child: Container(
                padding: const EdgeInsets.all(6.0),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.file_download_rounded, color: color, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── SHARED UTILITY COMPONENTS ───────────────────────────────────────────────────────────

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
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.4))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}