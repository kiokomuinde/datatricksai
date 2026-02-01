import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; 

// ===========================================================================
// DATATRICKS AI - AUTHENTICATION PAGE
// ===========================================================================

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with TickerProviderStateMixin {
  bool _isLogin = true; // Toggle between Sign In and Sign Up

  // Form Controllers
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _nameController = TextEditingController();

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  // NAVIGATION ACTION
  void _navigateToCareers() {
    Navigator.pushNamed(context, '/careers');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020408),
      body: Stack(
        children: [
          // 1. REUSED BACKGROUND
          const _AuthBackgroundCanvas(),

          // 2. CENTERED GLASS CARD
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // HEADER
                  const _AuthHeader(),
                  const SizedBox(height: 30),

                  // Glassmorphic Form Container
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 450),
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A).withOpacity(0.6),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Animated Title
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Text(
                                _isLogin ? "Welcome Back" : "Join the Hive",
                                key: ValueKey(_isLogin),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _isLogin
                                  ? "Enter your credentials to access the platform."
                                  : "Start earning or training models today.",
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white54),
                            ),
                            const SizedBox(height: 40),

                            // SOCIAL BUTTON (LINKED TO CAREERS)
                            _SocialButton(
                              icon: FontAwesomeIcons.google, 
                              label: "Continue with Google",
                              onTap: _navigateToCareers, // Navigates to Careers
                            ),

                            const SizedBox(height: 30),
                            const _DividerText(text: "or continue with email"),
                            const SizedBox(height: 30),

                            // FORM INPUTS
                            if (!_isLogin) ...[
                              _NeonStrikeInput(
                                hint: "Full Name",
                                icon: Icons.person_outline,
                                controller: _nameController,
                              ),
                              const SizedBox(height: 20),
                            ],

                            _NeonStrikeInput(
                              hint: "Email Address",
                              icon: Icons.email_outlined,
                              controller: _emailController,
                            ),
                            const SizedBox(height: 20),

                            _NeonStrikeInput(
                              hint: "Password",
                              icon: Icons.lock_outline,
                              isPassword: true,
                              controller: _passController,
                            ),

                            if (_isLogin) ...[
                              const SizedBox(height: 15),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {},
                                  child: const Text(
                                    "Forgot Password?",
                                    style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 30),

                            // ACTION BUTTON (LINKED TO CAREERS)
                            _GradientButton(
                              text: _isLogin ? "Sign In" : "Create Account",
                              onPressed: _navigateToCareers, // Navigates to Careers
                            ),

                            const SizedBox(height: 30),

                            // TOGGLE FOOTER
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _isLogin ? "Don't have an account?" : "Already have an account?",
                                  style: const TextStyle(color: Colors.white60),
                                ),
                                TextButton(
                                  onPressed: _toggleAuthMode,
                                  child: Text(
                                    _isLogin ? "Sign Up" : "Sign In",
                                    style: const TextStyle(
                                      color: Color(0xFFEC4899),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// CORE COMPONENT: NEON STRIKE INPUT
// ===========================================================================

class _NeonStrikeInput extends StatefulWidget {
  final String hint;
  final IconData icon;
  final bool isPassword;
  final TextEditingController controller;

  const _NeonStrikeInput({
    required this.hint,
    required this.icon,
    required this.controller,
    this.isPassword = false,
  });

  @override
  State<_NeonStrikeInput> createState() => _NeonStrikeInputState();
}

class _NeonStrikeInputState extends State<_NeonStrikeInput> with SingleTickerProviderStateMixin {
  final FocusNode _focusNode = FocusNode();
  late AnimationController _animController;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _focusNode.addListener(() {
      setState(() {
        _hasFocus = _focusNode.hasFocus;
        if (_hasFocus) {
          _animController.repeat();
        } else {
          _animController.stop();
          _animController.reset();
        }
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return CustomPaint(
          painter: _hasFocus ? _StrikeBorderPainter(progress: _animController.value) : null,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF020408),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _hasFocus ? Colors.transparent : Colors.white10, 
                width: 1.5
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              focusNode: _focusNode,
              controller: widget.controller,
              obscureText: widget.isPassword,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: widget.hint,
                hintStyle: const TextStyle(color: Colors.white38),
                icon: Icon(
                  widget.icon, 
                  color: _hasFocus ? const Color(0xFFEC4899) : Colors.white24
                ),
                suffixIcon: widget.isPassword 
                    ? const Icon(Icons.visibility_off, color: Colors.white24, size: 20) 
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }
}

// THE PAINTER THAT CREATES THE ROTATING GRADIENT "STRIKE"
class _StrikeBorderPainter extends CustomPainter {
  final double progress;
  _StrikeBorderPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    paint.shader = SweepGradient(
      startAngle: 0.0,
      endAngle: math.pi * 2,
      colors: const [
        Color(0xFF6366F1), // Indigo
        Color(0xFFEC4899), // Pink
        Colors.transparent,
        Colors.transparent,
        Color(0xFF6366F1), // Loop back
      ],
      stops: const [0.0, 0.25, 0.5, 0.9, 1.0],
      transform: GradientRotation(progress * math.pi * 2), 
    ).createShader(rect);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _StrikeBorderPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ===========================================================================
// SMOKE ANIMATION CLASSES
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
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _controller.addListener(() {
      _updateParticles();
    });
  }

  void _updateParticles() {
    if (_random.nextDouble() < 0.2) { 
      _particles.add(_SmokeParticle(
        x: widget.width / 2 + (_random.nextDouble() * 20 - 10),
        y: widget.height, 
        size: _random.nextDouble() * 5 + 2,
        speed: _random.nextDouble() * 1.5 + 0.5,
        color: _random.nextBool() ? Colors.purpleAccent : Colors.pinkAccent,
      ));
    }

    for (var particle in _particles) {
      particle.y -= particle.speed;
      particle.x += (_random.nextDouble() * 1.0 - 0.5); 
      particle.life -= 0.01;
      particle.size += 0.05; 
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
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.width, widget.height),
          painter: _SmokePainter(_particles),
        );
      },
    );
  }
}

class _SmokeParticle {
  double x;
  double y;
  double size;
  double speed;
  double life = 1.0; 
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
// SUB-COMPONENTS
// ===========================================================================

class _AuthHeader extends StatelessWidget {
  const _AuthHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            const Positioned(
              bottom: 0,
              child: _SmokeEffect(width: 80, height: 100),
            ),
            Image.asset(
              'assets/images/logo.png',
              height: 60,
              fit: BoxFit.contain,
            ),
          ],
        ),
        const SizedBox(width: 15),
        const Text(
          "DATATRICKS AI",
          style: TextStyle(
            color: Colors.white, 
            fontWeight: FontWeight.bold, 
            fontSize: 24, 
            letterSpacing: -1
          ),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap; // Updated to accept tap callback

  const _SocialButton({
    required this.icon, 
    required this.label,
    required this.onTap, // Required now
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _DividerText extends StatelessWidget {
  final String text;
  const _DividerText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(text, style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ),
        Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
      ],
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const _GradientButton({required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFFEC4899)], // Indigo to Pink
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF6366F1),
            blurRadius: 20,
            offset: Offset(0, 5),
            spreadRadius: -5,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }
}

// ===========================================================================
// BACKGROUND
// ===========================================================================

class _AuthBackgroundCanvas extends StatelessWidget {
  const _AuthBackgroundCanvas();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(painter: _AuthNetworkPainter()),
    );
  }
}

class _AuthNetworkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF020408);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final gridPaint = Paint()..color = Colors.white.withOpacity(0.02)..strokeWidth = 1;
    double gridSize = 40;
    for (double i = 0; i < size.width; i += gridSize) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = 0; i < size.height; i += gridSize) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    final orbPaint = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFF6366F1).withOpacity(0.2), Colors.transparent],
        radius: 0.6,
      ).createShader(Rect.fromCircle(center: const Offset(0, 0), radius: 600));
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.2), 600, orbPaint);

    final orbPaint2 = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFFEC4899).withOpacity(0.15), Colors.transparent],
        radius: 0.6,
      ).createShader(Rect.fromCircle(center: Offset(size.width, size.height), radius: 500));
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.8), 500, orbPaint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}