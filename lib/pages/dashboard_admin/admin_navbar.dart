import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class AdminNavbar extends StatelessWidget {
  final VoidCallback onLogout;
  final VoidCallback onDeleteSelected;
  final VoidCallback onSelectAll;
  final int selectedCount;
  final int totalDocs;
  final bool isAllSelected;

  const AdminNavbar({
    super.key,
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
              Row(
                children: [
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