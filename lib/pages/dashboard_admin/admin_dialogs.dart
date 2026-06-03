import 'package:flutter/material.dart';

class VerifyConfirmDialog extends StatefulWidget {
  final String fullName;
  final String email;
  final bool isApproving;

  const VerifyConfirmDialog({
    super.key,
    required this.fullName,
    required this.email,
    required this.isApproving,
  });

  @override
  State<VerifyConfirmDialog> createState() => _VerifyConfirmDialogState();
}

class _VerifyConfirmDialogState extends State<VerifyConfirmDialog> with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 340))..forward();
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
    final accentColor = isApproving ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    final headerTop = isApproving ? const Color(0xFF0D2E22) : const Color(0xFF2E1F0A);
    final headerBot = isApproving ? const Color(0xFF0A1F18) : const Color(0xFF1C1205);

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
                border: Border.all(color: accentColor.withValues(alpha: 0.35), width: 1.5),
                boxShadow: [
                  BoxShadow(color: accentColor.withValues(alpha: 0.20), blurRadius: 50, spreadRadius: 2, offset: const Offset(0, 16)),
                  BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 30, offset: const Offset(0, 8)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 36),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [headerTop, headerBot], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                      ),
                      child: Column(children: [
                        Stack(alignment: Alignment.center, children: [
                          Container(width: 90, height: 90, decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.08), shape: BoxShape.circle)),
                          Container(width: 68, height: 68, decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.15), shape: BoxShape.circle)),
                          Container(
                            width: 50, height: 50,
                            decoration: BoxDecoration(
                              color: accentColor,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: accentColor.withValues(alpha: 0.5), blurRadius: 18, spreadRadius: 2)],
                            ),
                            child: Icon(isApproving ? Icons.verified_user_rounded : Icons.remove_moderator_rounded, color: Colors.white, size: 26),
                          ),
                        ]),
                        const SizedBox(height: 18),
                        Text(
                          isApproving ? 'Confirm Verification' : 'Revoke Verification',
                          style: TextStyle(color: accentColor, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.3),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isApproving ? 'You are about to approve this user' : 'You are about to revoke this user\'s access',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 13),
                        ),
                      ]),
                    ),
                    // Body
                    Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('USER TO BE ${isApproving ? 'VERIFIED' : 'REVOKED'}',
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.4)),
                              const SizedBox(height: 14),
                              Row(children: [
                                Container(
                                  width: 44, height: 44,
                                  decoration: BoxDecoration(
                                    color: accentColor.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: accentColor.withValues(alpha: 0.4), width: 1.5),
                                  ),
                                  child: Center(
                                    child: Text(
                                      widget.fullName.isNotEmpty ? widget.fullName[0].toUpperCase() : '?',
                                      style: TextStyle(color: accentColor, fontSize: 18, fontWeight: FontWeight.w900),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(widget.fullName.isEmpty ? 'Unknown User' : widget.fullName,
                                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                                          maxLines: 1, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 4),
                                      Row(children: [
                                        Icon(Icons.email_outlined, size: 13, color: Colors.white.withValues(alpha: 0.4)),
                                        const SizedBox(width: 5),
                                        Expanded(child: Text(widget.email, style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                      ]),
                                    ],
                                  ),
                                ),
                              ]),
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                                decoration: BoxDecoration(
                                  color: accentColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: accentColor.withValues(alpha: 0.25)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _StatusPill(label: isApproving ? 'Pending' : 'Verified', color: isApproving ? const Color(0xFFF59E0B) : const Color(0xFF10B981)),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      child: Icon(Icons.arrow_forward_rounded, color: Colors.white.withValues(alpha: 0.3), size: 16),
                                    ),
                                    _StatusPill(label: isApproving ? 'Verified' : 'Pending', color: isApproving ? const Color(0xFF10B981) : const Color(0xFFF59E0B)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
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
                              Icon(Icons.info_outline_rounded, size: 15, color: Colors.white.withValues(alpha: 0.3)),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  isApproving
                                      ? 'This will grant the user full access to the platform. They will be notified of their approved status.'
                                      : 'This will remove the user\'s verified status and set them back to pending review.',
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12, height: 1.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => Navigator.of(context).pop(false),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                ),
                                child: const Center(child: Text('Cancel', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w700, fontSize: 14))),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
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
                                  boxShadow: [BoxShadow(color: accentColor.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 4))],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(isApproving ? Icons.verified_rounded : Icons.remove_moderator_rounded, color: Colors.white, size: 18),
                                    const SizedBox(width: 8),
                                    Text(isApproving ? 'Yes, Verify User' : 'Yes, Revoke Access', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
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

class ExamGradeDialog extends StatefulWidget {
  final String fullName;
  final String email;
  final String currentExamStatus;

  const ExamGradeDialog({
    super.key,
    required this.fullName,
    required this.email,
    required this.currentExamStatus,
  });

  @override
  State<ExamGradeDialog> createState() => _ExamGradeDialogState();
}

class _ExamGradeDialogState extends State<ExamGradeDialog> with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _scale;
  late Animation<double> _fade;
  String? _selected; 

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 340))..forward();
    _scale = CurvedAnimation(parent: _anim, curve: Curves.easeOutBack);
    _fade  = CurvedAnimation(parent: _anim, curve: Curves.easeIn);

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
                border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.35), width: 1.5),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: 0.18), blurRadius: 50, spreadRadius: 2, offset: const Offset(0, 16)),
                  BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 30, offset: const Offset(0, 8)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0xFF1E1B4B), Color(0xFF0F0E2A)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                      ),
                      child: Column(children: [
                        Stack(alignment: Alignment.center, children: [
                          Container(width: 88, height: 88, decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.08), shape: BoxShape.circle)),
                          Container(width: 66, height: 66, decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.15), shape: BoxShape.circle)),
                          Container(
                            width: 50, height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1),
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: 0.50), blurRadius: 18, spreadRadius: 2)],
                            ),
                            child: const Icon(Icons.fact_check_rounded, color: Colors.white, size: 26),
                          ),
                        ]),
                        const SizedBox(height: 18),
                        const Text('Grade Exam', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.3)),
                        const SizedBox(height: 5),
                        Text('Select a result for this applicant\'s exam', style: TextStyle(color: Colors.white.withValues(alpha: 0.40), fontSize: 13)),
                      ]),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        children: [
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
                                  border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.4), width: 1.5),
                                ),
                                child: Center(
                                  child: Text(
                                    widget.fullName.isNotEmpty ? widget.fullName[0].toUpperCase() : '?',
                                    style: const TextStyle(color: Color(0xFF818CF8), fontSize: 18, fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(widget.fullName.isEmpty ? 'Unknown User' : widget.fullName, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 3),
                                  Row(children: [
                                    Icon(Icons.email_outlined, size: 12, color: Colors.white.withValues(alpha: 0.35)),
                                    const SizedBox(width: 5),
                                    Expanded(child: Text(widget.email, style: TextStyle(color: Colors.white.withValues(alpha: 0.50), fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                  ]),
                                ]),
                              ),
                            ]),
                          ),
                          const SizedBox(height: 20),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text('SELECT RESULT', style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.4)),
                          ),
                          const SizedBox(height: 12),
                          Row(children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _selected = 'passed'),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  decoration: BoxDecoration(
                                    color: _selected == 'passed' ? const Color(0xFF10B981).withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.03),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: _selected == 'passed' ? const Color(0xFF10B981) : Colors.white.withValues(alpha: 0.10), width: _selected == 'passed' ? 2.0 : 1.0),
                                    boxShadow: _selected == 'passed' ? [BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 4))] : [],
                                  ),
                                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                    Container(
                                      width: 46, height: 46,
                                      decoration: BoxDecoration(color: _selected == 'passed' ? const Color(0xFF10B981).withValues(alpha: 0.20) : Colors.white.withValues(alpha: 0.05), shape: BoxShape.circle),
                                      child: Icon(Icons.check_circle_rounded, color: _selected == 'passed' ? const Color(0xFF10B981) : Colors.white24, size: 26),
                                    ),
                                    const SizedBox(height: 10),
                                    Text('PASSED', style: TextStyle(color: _selected == 'passed' ? const Color(0xFF10B981) : Colors.white38, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.0)),
                                  ]),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _selected = 'failed'),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  decoration: BoxDecoration(
                                    color: _selected == 'failed' ? const Color(0xFFEF4444).withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.03),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: _selected == 'failed' ? const Color(0xFFEF4444) : Colors.white.withValues(alpha: 0.10), width: _selected == 'failed' ? 2.0 : 1.0),
                                    boxShadow: _selected == 'failed' ? [BoxShadow(color: const Color(0xFFEF4444).withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 4))] : [],
                                  ),
                                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                    Container(
                                      width: 46, height: 46,
                                      decoration: BoxDecoration(color: _selected == 'failed' ? const Color(0xFFEF4444).withValues(alpha: 0.20) : Colors.white.withValues(alpha: 0.05), shape: BoxShape.circle),
                                      child: Icon(Icons.cancel_rounded, color: _selected == 'failed' ? const Color(0xFFEF4444) : Colors.white24, size: 26),
                                    ),
                                    const SizedBox(height: 10),
                                    Text('FAILED', style: TextStyle(color: _selected == 'failed' ? const Color(0xFFEF4444) : Colors.white38, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.0)),
                                  ]),
                                ),
                              ),
                            ),
                          ]),
                          const SizedBox(height: 24),
                          Row(children: [
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
                                  child: const Center(child: Text('Cancel', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w700, fontSize: 14))),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: InkWell(
                                onTap: canConfirm ? () => Navigator.of(context).pop(_selected) : null,
                                borderRadius: BorderRadius.circular(14),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  decoration: BoxDecoration(
                                    color: canConfirm ? (_selected == 'passed' ? const Color(0xFF10B981) : const Color(0xFFEF4444)) : Colors.white.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: canConfirm ? [BoxShadow(color: (_selected == 'passed' ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.40), blurRadius: 16, offset: const Offset(0, 4))] : [],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _selected == 'passed' ? Icons.check_circle_rounded : _selected == 'failed' ? Icons.cancel_rounded : Icons.fact_check_rounded,
                                        color: canConfirm ? Colors.white : Colors.white24, size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        canConfirm ? (_selected == 'passed' ? 'Confirm Pass' : 'Confirm Fail') : 'Select a Result',
                                        style: TextStyle(color: canConfirm ? Colors.white : Colors.white24, fontWeight: FontWeight.w800, fontSize: 14),
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
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}