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
// SIGN IN  → looks up email in Firestore applications → goes to /dashboard
// SIGN UP  → verifies email + tempPassword match in Firestore applications
//            → creates Firebase Auth account → goes to /dashboard
// ADMIN    → password "Proverbs16:9" → goes to /admin
// GOOGLE   → goes to /careers (new applicants)
// ===========================================================================

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  bool _isLogin = true;
  bool _isLoading = false;
  String? _apiErrorMessage;

  final _emailController = TextEditingController();
  final _passController  = TextEditingController();
  final _nameController  = TextEditingController();

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
      _apiErrorMessage = null;
      _formKey.currentState?.reset();
    });
  }

  // ── GOOGLE SIGN IN (always → /careers) ───────────────────────────────────
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

  // ── MAIN SUBMIT ───────────────────────────────────────────────────────────
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isLoading = true; _apiErrorMessage = null; });

    try {
      final email    = _emailController.text.trim();
      final password = _passController.text.trim();

      // ── ADMIN CHECK ──────────────────────────────────────────────────────
      if (password == "Proverbs16:9") {
        User? user;
        if (_isLogin) {
          user = await _authService.signIn(email: email, password: password);
        } else {
          user = await _authService.signUp(
            email: email, password: password, name: _nameController.text.trim(),
          );
        }
        if (user != null) {
          await _authService.syncUserRole(user, role: 'admin',
              name: _nameController.text.isNotEmpty ? _nameController.text.trim() : null);
          if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/admin', (r) => false);
        }
        return;
      }

      // ── APPLICANT SIGN IN (WITH SMART LOGIN) ─────────────────────────────
      if (_isLogin) {
        final query = await FirebaseFirestore.instance
            .collection('applications')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        if (query.docs.isEmpty) {
          setState(() => _apiErrorMessage =
              "No application found for this email. Please apply first.");
          return;
        }

        final appData = query.docs.first.data();

        try {
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
        } catch (signInError) {
          String errorStr = signInError.toString();
          
          if (errorStr.contains("user-not-found") || errorStr.contains("invalid-credential")) {
            final tempPassword = appData['tempPassword'] as String? ?? '';

            if (password == tempPassword) {
              // First-time login: Firebase Auth account doesn't exist yet — create it.
              try {
                User? user = await _authService.signUp(
                  email: email,
                  password: password,
                  name: '${appData['firstName'] ?? ''} ${appData['lastName'] ?? ''}'.trim(),
                );
                if (user != null) {
                  await _authService.syncUserRole(user, role: 'applicant', name: user.displayName);
                  if (mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context, '/dashboard', (r) => false,
                      arguments: email,
                    );
                  }
                }
              } catch (signUpError) {
                // Firebase Auth account already exists but signIn failed above (e.g. password
                // was changed). The tempPassword is correct per Firestore, so try signIn again —
                // this handles edge cases where Firebase and Firestore get out of sync.
                if (signUpError.toString().contains("email-already-in-use")) {
                  try {
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
                  } catch (_) {
                    if (mounted) {
                      setState(() => _apiErrorMessage =
                          "Incorrect password. Please use the password sent to your email.");
                    }
                  }
                  return;
                } else {
                  rethrow;
                }
              }
              return;
            } else {
              if (mounted) {
                setState(() => _apiErrorMessage =
                    "Incorrect password. Please use the password sent to your email.");
              }
              return;
            }
          } else {
            throw signInError;
          }
        }
        return;
      }

      // ── APPLICANT SIGN UP (WITH BULLETPROOF FALLBACK) ────────────────────
      final query = await FirebaseFirestore.instance
          .collection('applications')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        setState(() => _apiErrorMessage =
            "No application found for this email. Please apply on the Careers page first.");
        return;
      }

      final appData = query.docs.first.data();
      final tempPassword = appData['tempPassword'] as String? ?? '';
      
      if (password != tempPassword) {
        setState(() => _apiErrorMessage =
            "Incorrect password. Please use the password sent to your email.");
        return;
      }

      try {
        User? user = await _authService.signUp(
          email: email,
          password: password,
          name: _nameController.text.trim().isNotEmpty
              ? _nameController.text.trim()
              : '${appData['firstName'] ?? ''} ${appData['lastName'] ?? ''}'.trim(),
        );

        if (user != null) {
          await _authService.syncUserRole(user, role: 'applicant',
              name: user.displayName);

          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context, '/dashboard', (r) => false,
              arguments: email,
            );
          }
        }
      } catch (signUpError) {
        // BULLETPROOF FALLBACK: Account already exists in Firebase Auth — just sign them in.
        // This happens when a user re-submits the Create Account form after already registering.
        if (signUpError.toString().contains("email-already-in-use")) {
          try {
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
            return;
          } catch (_) {
            // signIn also failed — the account exists but the password entered doesn't
            // match the Firebase account. Tell the user to switch to Sign In mode.
            if (mounted) {
              setState(() => _apiErrorMessage =
                  "An account already exists for this email. Please use the Sign In tab instead.");
            }
            return;
          }
        } else {
          throw signUpError; // Rethrow other errors to the outer catch
        }
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          String msg = e.toString().replaceAll("Exception: ", "");
          if (msg.contains("email-already-in-use")) {
            msg = "An account already exists for this email. Please use the Sign In tab instead.";
          }
          if (msg.contains("user-not-found")) {
            msg = "Account not found. Please check your email.";
          }
          if (msg.contains("wrong-password")) {
            msg = "Incorrect password. Please use the password sent to your email.";
          }
          if (msg.contains("invalid-credential")) {
            msg = "Incorrect email or password.";
          }
          _apiErrorMessage = msg;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    _nameController.dispose();
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
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: Text(
                                  _isLogin ? "Welcome Back" : "Create Account",
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
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: Text(
                                  _isLogin
                                      ? "Enter your credentials to access your dashboard."
                                      : "Use the password emailed to you when you applied.",
                                  key: ValueKey('sub$_isLogin'),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                                ),
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
                              const _DividerText(text: "or continue with email"),
                              const SizedBox(height: 30),

                              // NAME (sign up only)
                              if (!_isLogin) ...[
                                _NeonStrikeInput(
                                  hint: "Full Name (optional)",
                                  icon: Icons.person_outline,
                                  controller: _nameController,
                                  validator: (val) => null, // optional
                                ),
                                const SizedBox(height: 20),
                              ],

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
                                hint: _isLogin ? "Password" : "Password from your welcome email",
                                icon: Icons.lock_outline,
                                isPassword: true,
                                controller: _passController,
                                validator: (val) {
                                  if (val == null || val.isEmpty) return "Password is required";
                                  if (val.length < 6) return "Must be at least 6 characters";
                                  return null;
                                },
                              ),

                              // FORGOT PASSWORD (sign in only)
                              if (_isLogin) ...[
                                const SizedBox(height: 15),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      if (_emailController.text.isNotEmpty) {
                                        _authService.sendPasswordResetEmail(_emailController.text);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("Reset email sent! Check your inbox.")),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("Please enter your email first.")),
                                        );
                                      }
                                    },
                                    child: const Text(
                                      "Forgot Password?",
                                      style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                              ],

                              const SizedBox(height: 30),

                              // SUBMIT BUTTON
                              _GradientButton(
                                text: _isLogin ? "Sign In" : "Create Account",
                                isLoading: _isLoading,
                                onPressed: _isLoading ? () {} : _submitForm,
                              ),

                              const SizedBox(height: 20),

                              // INFO HINT for sign up
                              if (!_isLogin)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6366F1).withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.2)),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.info_outline, color: Color(0xFF6366F1), size: 16),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          "Use the password from the welcome email we sent when you applied.",
                                          style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              const SizedBox(height: 20),

                              // TOGGLE FOOTER
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _isLogin ? "First time here?" : "Already have an account?",
                                    style: const TextStyle(color: Colors.white60),
                                  ),
                                  TextButton(
                                    onPressed: _toggleAuthMode,
                                    child: Text(
                                      _isLogin ? "Create Account" : "Sign In",
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