import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:datatricksai/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ===========================================================================
// DATATRICKS AI - AUTHENTICATION PAGE
// ===========================================================================
// SIGN IN  → logs in via Firebase Auth → goes to /dashboard
// ADMIN    → password "Proverbs16:9" → goes to /admin
// GOOGLE   → goes to /careers (new applicants)
// NO SIGN UP → New users are directed to apply on the Careers page.
// ===========================================================================

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String? _apiErrorMessage;

  final _emailController = TextEditingController();
  final _passController  = TextEditingController();

  // ── GOOGLE SIGN IN (always → /careers for new applicants) ───────────────
  Future<void> _handleGoogleSignIn() async {
    setState(() { _isLoading = true; _apiErrorMessage = null; });
    try {
      User? user = await _authService.signInWithGoogle();
      if (user != null) {
        await _authService.syncUserRole(user, role: 'applicant');
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/careers', (r) => false);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _apiErrorMessage = e.toString().replaceAll("Exception: ", ""));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── MAIN SIGN IN SUBMIT ──────────────────────────────────────────────────
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isLoading = true; _apiErrorMessage = null; });

    try {
      final email    = _emailController.text.trim();
      final password = _passController.text.trim();

      // ── ADMIN CHECK (Backdoor creation if admin doesn't exist yet) ────────
      if (password == "Proverbs16:9") {
        try {
          User? user = await _authService.signIn(email: email, password: password);
          if (user != null) {
            await _authService.syncUserRole(user, role: 'admin');
            if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/admin', (r) => false);
          }
        } catch (adminErr) {
          if (adminErr.toString().contains("user-not-found") || 
              adminErr.toString().contains("invalid-credential") ||
              adminErr.toString().contains("invalid-login-credentials")) {
            User? user = await _authService.signUp(
              email: email, password: password, name: "Admin",
            );
            if (user != null) {
              await _authService.syncUserRole(user, role: 'admin', name: "Admin");
              if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/admin', (r) => false);
            }
          } else {
            rethrow;
          }
        }
        return;
      }

      // ── STANDARD APPLICANT SIGN IN ───────────────────────────────────────
      User? user = await _authService.signIn(email: email, password: password);

      if (user != null) {
        await _authService.syncUserRole(user, role: 'applicant');
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context, '/dashboard', (r) => false,
            arguments: email,
          );
        }
      }
      
    } catch (e) {
      if (mounted) {
        setState(() {
          String msg = e.toString().replaceAll("Exception: ", "");
          // Firebase occasionally throws invalid-credential instead of user-not-found for security
          if (msg.contains("user-not-found") || 
              msg.contains("invalid-credential") || 
              msg.contains("invalid-login-credentials")) {
            msg = "Account not found or incorrect password. If you are new, please apply via the Careers page first.";
          } else if (msg.contains("wrong-password")) {
            msg = "Incorrect password. Please use the password sent to your email or reset it.";
          }
          _apiErrorMessage = msg;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── LAUNCH FORGOT PASSWORD DIALOG ─────────────────────────────────────────
  void _showForgotPasswordDialog() {
    // Pass the current text from the email controller to pre-fill the dialog
    final currentEmail = _emailController.text.trim();
    
    showDialog(
      context: context,
      barrierDismissible: false, // Force user to close via button
      builder: (context) {
        return _ForgotPasswordDialog(initialEmail: currentEmail);
      },
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020408),
      body: Stack(
        children: [
          const _AuthBackgroundCanvas(),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const _AuthHeader(),
                  const SizedBox(height: 30),

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
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [

                              // TITLE
                              const Text(
                                "Welcome Back",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                "Enter your credentials to access your dashboard.",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white54, fontSize: 13),
                              ),

                              // API ERROR BANNER
                              if (_apiErrorMessage != null) ...[
                                const SizedBox(height: 20),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.5)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 20),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _apiErrorMessage!,
                                          style: const TextStyle(color: Colors.white, fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 30),

                              // GOOGLE BUTTON
                              _SocialButton(
                                icon: FontAwesomeIcons.google,
                                label: "Continue with Google",
                                onTap: _isLoading ? () {} : _handleGoogleSignIn,
                              ),

                              const SizedBox(height: 30),
                              const _DividerText(text: "or sign in with email"),
                              const SizedBox(height: 30),

                              // EMAIL
                              _NeonStrikeInput(
                                hint: "Email Address",
                                icon: Icons.email_outlined,
                                controller: _emailController,
                                validator: (val) {
                                  if (val == null || val.isEmpty) return "Email is required";
                                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) {
                                    return "Invalid email format";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // PASSWORD
                              _NeonStrikeInput(
                                hint: "Password",
                                icon: Icons.lock_outline,
                                isPassword: true,
                                controller: _passController,
                                validator: (val) {
                                  if (val == null || val.isEmpty) return "Password is required";
                                  return null;
                                },
                              ),

                              // FORGOT PASSWORD POPUP TRIGGER
                              const SizedBox(height: 15),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _isLoading ? null : _showForgotPasswordDialog,
                                  child: const Text(
                                    "Forgot Password?",
                                    style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 30),

                              // SUBMIT BUTTON
                              _GradientButton(
                                text: "Sign In",
                                isLoading: _isLoading,
                                onPressed: _isLoading ? () {} : _submitForm,
                              ),

                              const SizedBox(height: 20),

                              // REDIRECT NEW USERS TO CAREERS PAGE
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    "Don't have an account?",
                                    style: TextStyle(color: Colors.white60),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pushNamed(context, '/careers'),
                                    child: const Text(
                                      "Apply Here",
                                      style: TextStyle(
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
// FORGOT PASSWORD DIALOG COMPONENT
// ===========================================================================

class _ForgotPasswordDialog extends StatefulWidget {
  final String initialEmail;
  const _ForgotPasswordDialog({required this.initialEmail});

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  late TextEditingController _dialogEmailController;
  bool _isLoading = false;
  String? _message;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _dialogEmailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _dialogEmailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    final email = _dialogEmailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _message = "Please enter an email address.";
        _isSuccess = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      setState(() {
        _message = "Success! A reset link has been sent to your email.";
        _isSuccess = true;
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _message = e.message ?? "Failed to send reset link.";
        _isSuccess = false;
      });
    } catch (e) {
      setState(() {
        _message = "An unexpected error occurred. Please try again.";
        _isSuccess = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withOpacity(0.8),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.6),
                  blurRadius: 40,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.lock_reset, color: Color(0xFF6366F1), size: 48),
                const SizedBox(height: 20),
                const Text(
                  "Reset Password",
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  "Enter the email associated with your account and we'll send you a link to reset your password.",
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 25),

                // Status Message Area
                if (_message != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: _isSuccess 
                          ? const Color(0xFF10B981).withOpacity(0.15) 
                          : const Color(0xFFEF4444).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _isSuccess 
                            ? const Color(0xFF10B981).withOpacity(0.5) 
                            : const Color(0xFFEF4444).withOpacity(0.5)
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isSuccess ? Icons.check_circle_outline : Icons.error_outline, 
                          color: _isSuccess ? const Color(0xFF10B981) : const Color(0xFFEF4444), 
                          size: 20
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _message!,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                _NeonStrikeInput(
                  hint: "Email Address",
                  icon: Icons.email_outlined,
                  controller: _dialogEmailController,
                ),
                const SizedBox(height: 30),

                // Action Buttons
                _GradientButton(
                  text: "Send Reset Link",
                  isLoading: _isLoading,
                  onPressed: _isLoading ? () {} : _sendResetEmail,
                ),
                const SizedBox(height: 15),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    "Close",
                    style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w600),
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

// ===========================================================================
// NEON STRIKE INPUT
// ===========================================================================

class _NeonStrikeInput extends StatefulWidget {
  final String hint;
  final IconData icon;
  final bool isPassword;
  final TextEditingController controller;
  final String? Function(String?)? validator;

  const _NeonStrikeInput({
    required this.hint,
    required this.icon,
    required this.controller,
    this.isPassword = false,
    this.validator,
  });

  @override
  State<_NeonStrikeInput> createState() => _NeonStrikeInputState();
}

class _NeonStrikeInputState extends State<_NeonStrikeInput> with SingleTickerProviderStateMixin {
  final FocusNode _focusNode = FocusNode();
  late AnimationController _animController;
  bool _hasFocus = false;
  bool _isObscured = true;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
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
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextFormField(
              focusNode: _focusNode,
              controller: widget.controller,
              obscureText: widget.isPassword && _isObscured,
              validator: widget.validator,
              style: const TextStyle(color: Colors.white),
              cursorColor: const Color(0xFFEC4899),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: widget.hint,
                hintStyle: const TextStyle(color: Colors.white38),
                errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w500),
                icon: Icon(widget.icon, color: _hasFocus ? const Color(0xFFEC4899) : Colors.white24),
                suffixIcon: widget.isPassword
                    ? GestureDetector(
                        onTap: () => setState(() => _isObscured = !_isObscured),
                        child: Icon(
                          _isObscured ? Icons.visibility_off : Icons.visibility,
                          color: Colors.white24,
                          size: 20,
                        ),
                      )
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StrikeBorderPainter extends CustomPainter {
  final double progress;
  _StrikeBorderPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rect  = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 2.0;
    paint.shader = SweepGradient(
      startAngle: 0.0,
      endAngle: math.pi * 2,
      colors: const [
        Color(0xFF6366F1),
        Color(0xFFEC4899),
        Colors.transparent,
        Colors.transparent,
        Color(0xFF6366F1),
      ],
      stops: const [0.0, 0.25, 0.5, 0.9, 1.0],
      transform: GradientRotation(progress * math.pi * 2),
    ).createShader(rect);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _StrikeBorderPainter old) => old.progress != progress;
}

// ===========================================================================
// SMOKE ANIMATION
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
    if (_random.nextDouble() < 0.2) {
      _particles.add(_SmokeParticle(
        x: widget.width / 2 + (_random.nextDouble() * 20 - 10),
        y: widget.height,
        size: _random.nextDouble() * 5 + 2,
        speed: _random.nextDouble() * 1.5 + 0.5,
        color: _random.nextBool() ? Colors.purpleAccent : Colors.pinkAccent,
      ));
    }
    for (var p in _particles) {
      p.y -= p.speed;
      p.x += (_random.nextDouble() * 1.0 - 0.5);
      p.life -= 0.01;
      p.size += 0.05;
    }
    _particles.removeWhere((p) => p.life <= 0);
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

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
  double x, y, size, speed;
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
      canvas.drawCircle(
        Offset(p.x, p.y),
        p.size,
        Paint()
          ..color = p.color.withOpacity(p.life * 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
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
            const Positioned(bottom: 0, child: _SmokeEffect(width: 80, height: 100)),
            Image.asset(
              'assets/images/logo.png',
              height: 60,
              fit: BoxFit.contain,
              errorBuilder: (c, e, s) => const Icon(FontAwesomeIcons.robot, size: 60, color: Colors.white),
            ),
          ],
        ),
        const SizedBox(width: 15),
        const Text(
          "DATATRICKS AI",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24, letterSpacing: -1),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SocialButton({required this.icon, required this.label, required this.onTap});

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
  final bool isLoading;
  const _GradientButton({required this.text, required this.onPressed, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0xFF6366F1), blurRadius: 20, offset: Offset(0, 5), spreadRadius: -5),
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
        child: isLoading
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }
}

class _AuthBackgroundCanvas extends StatelessWidget {
  const _AuthBackgroundCanvas();

  @override
  Widget build(BuildContext context) => Positioned.fill(child: CustomPaint(painter: _AuthNetworkPainter()));
}

class _AuthNetworkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = const Color(0xFF020408));

    final gridPaint = Paint()..color = Colors.white.withOpacity(0.02)..strokeWidth = 1;
    for (double i = 0; i < size.width; i += 40) canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    for (double i = 0; i < size.height; i += 40) canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);

    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.2), 600,
      Paint()..shader = RadialGradient(
        colors: [const Color(0xFF6366F1).withOpacity(0.2), Colors.transparent],
      ).createShader(Rect.fromCircle(center: Offset(size.width * 0.2, size.height * 0.2), radius: 600)),
    );
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.8), 500,
      Paint()..shader = RadialGradient(
        colors: [const Color(0xFFEC4899).withOpacity(0.15), Colors.transparent],
      ).createShader(Rect.fromCircle(center: Offset(size.width * 0.8, size.height * 0.8), radius: 500)),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}