import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

// ===========================================================================
// DATATRICKS AI - HUMAN INTELLIGENCE PLATFORM
// ===========================================================================

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with TickerProviderStateMixin {
  late ScrollController _mainScrollController;
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _mainScrollController = ScrollController();
    _mainScrollController.addListener(() {
      setState(() {
        _scrollOffset = _mainScrollController.offset;
      });
    });
  }

  @override
  void dispose() {
    _mainScrollController.dispose();
    super.dispose();
  }

  // SCROLL ACTIONS
  void _scrollToTop() {
    if (_mainScrollController.hasClients) {
      _mainScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 600),
        curve: Curves.fastOutSlowIn,
      );
    }
  }

  void _scrollToBottom() {
    if (_mainScrollController.hasClients) {
      _mainScrollController.animateTo(
        _mainScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 600),
        curve: Curves.fastOutSlowIn,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. DYNAMIC BACKGROUND (Global Network)
          const _GlobalNetworkCanvas(),
          
          // 2. SCROLLABLE CONTENT
          Positioned.fill(
            child: SingleChildScrollView(
              controller: _mainScrollController,
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _HeroSection(offset: _scrollOffset),
                  const _TrustedBySection(),
                  const _ServiceCapabilityGrid(),
                  const _WorkforceRecruitmentSection(),
                  const _ProcessWorkflowSection(),
                  const _JoinTheTeamCTA(),
                  const _NewsletterSection(), 
                  const _Footer(),           
                ],
              ),
            ),
          ),

          // 3. GLASS NAVIGATION WITH SMOKE ANIMATION
          _FixedSmartNavbar(scrollOffset: _scrollOffset),

          // 4. SCROLL CONTROL BUTTONS
          Positioned(
            bottom: 40,
            right: 30,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: "scrollTopBtn",
                  onPressed: _scrollToTop,
                  mini: true,
                  backgroundColor: const Color(0xFF6366F1), // Indigo
                  child: const Icon(Icons.arrow_upward, color: Colors.white),
                ),
                const SizedBox(height: 15),
                FloatingActionButton(
                  heroTag: "scrollBottomBtn",
                  onPressed: _scrollToBottom,
                  mini: true,
                  backgroundColor: const Color(0xFFEC4899), // Pink
                  child: const Icon(Icons.arrow_downward, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// HERO SECTION
// ===========================================================================

class _HeroSection extends StatelessWidget {
  final double offset;
  const _HeroSection({required this.offset});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Container(
      constraints: BoxConstraints(minHeight: size.height),
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.08, vertical: 100),
      child: Stack(
        children: [
          // Animated Abstract Visual (Human-AI Connection)
          Positioned(
            right: -100,
            top: 100,
            child: Opacity(
              opacity: math.max(0, 1 - (offset / 500)),
              child: const _PulseConnectivityVisual(),
            ),
          ),
          
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 50),
              _buildPillBadge("RLHF & DATA ANNOTATION PLATFORM"),
              const SizedBox(height: 30),
              
              // Gradient Text
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.white, Color(0xFF6366F1), Color(0xFFEC4899)],
                  stops: [0.2, 0.6, 1.0],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: Text(
                  "Perfect Data Requires\nThe Human Touch.",
                  textAlign: isDesktop ? TextAlign.left : TextAlign.center,
                  style: Theme.of(context).textTheme.displayLarge,
                ),
              ),
              
              const SizedBox(height: 30),
              
              SizedBox(
                width: 650,
                child: Text(
                  "DataTricks AI connects world-class AI companies with a curated global workforce. We provide the tools to train models, and the people to perfect them.",
                  textAlign: isDesktop ? TextAlign.left : TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              
              const SizedBox(height: 50),
              
              // Dual Action Buttons
              Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: isDesktop ? WrapAlignment.start : WrapAlignment.center,
                children: [
                  _PrimaryButton(
                    text: "Hire Annotators",
                    icon: Icons.business_center,
                    onPressed: () {
                      // UPDATED: Navigates to Careers Page
                      Navigator.pushNamed(context, '/careers');
                    },
                    color: const Color(0xFF6366F1), // Indigo
                  ),
                  _PrimaryButton(
                    text: "Start Earning",
                    icon: Icons.monetization_on,
                    onPressed: () {
                      // UPDATED: Navigates to Careers Page
                      Navigator.pushNamed(context, '/careers');
                    },
                    color: const Color(0xFF10B981), // Emerald Green for Money
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
              
              // Social Proof Snippet
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: isDesktop ? MainAxisAlignment.start : MainAxisAlignment.center,
                children: [
                  const _AvatarStack(),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text("12,000+ Active Contributors", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text("Online now and ready to label", style: TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  )
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPillBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF6366F1),
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ===========================================================================
// SECTION: TRUSTED BY (Logos)
// ===========================================================================

class _TrustedBySection extends StatelessWidget {
  const _TrustedBySection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      decoration: BoxDecoration(
        border: Border.symmetric(horizontal: BorderSide(color: Colors.white.withOpacity(0.05))),
        color: Colors.white.withOpacity(0.02),
      ),
      child: Column(
        children: [
          const Text("TRUSTED BY ENGINEERING TEAMS AT", style: TextStyle(color: Colors.white38, letterSpacing: 2, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          Wrap(
            spacing: 60,
            runSpacing: 30,
            alignment: WrapAlignment.center,
            children: [
              _CompanyLogo(name: "TechFlow"),
              _CompanyLogo(name: "OpenScale"),
              _CompanyLogo(name: "Nebula AI"),
              _CompanyLogo(name: "Quantum"),
              _CompanyLogo(name: "DataCore"),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompanyLogo extends StatelessWidget {
  final String name;
  const _CompanyLogo({required this.name});

  @override
  Widget build(BuildContext context) {
    return Text(
      name.toUpperCase(),
      style: TextStyle(
        color: Colors.white.withOpacity(0.3),
        fontWeight: FontWeight.w900,
        fontSize: 22,
        letterSpacing: -1,
      ),
    );
  }
}

// ===========================================================================
// SECTION: SERVICE CAPABILITIES
// ===========================================================================

class _ServiceCapabilityGrid extends StatelessWidget {
  const _ServiceCapabilityGrid();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 20),
      child: Column(
        children: [
          const _SectionHeader(
            tag: "CAPABILITIES",
            title: "Data Solutions for Every Model",
            subtitle: "From Computer Vision to LLM fine-tuning, our diverse workforce handles edge cases that automated tools miss.",
          ),
          const SizedBox(height: 60),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: const [
              _ServiceCard(
                title: "RLHF for LLMs",
                description: "Human ranking of chatbot responses to reduce hallucinations and improve safety alignment.",
                icon: Icons.chat_bubble_outline,
                color: Color(0xFFEC4899),
              ),
              _ServiceCard(
                title: "Computer Vision",
                description: "Pixel-perfect bounding boxes, polygons, and semantic segmentation for autonomous systems.",
                icon: Icons.image_search,
                color: Color(0xFF6366F1),
              ),
              _ServiceCard(
                title: "Audio Transcription",
                description: "High-fidelity transcription and timestamping for multiple languages and dialects.",
                icon: Icons.graphic_eq,
                color: Color(0xFF10B981),
              ),
              _ServiceCard(
                title: "Content Moderation",
                description: "Real-time filtering of text, images, and video to ensure platform safety and compliance.",
                icon: Icons.shield_outlined,
                color: Color(0xFFF59E0B),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _ServiceCard({required this.title, required this.description, required this.icon, required this.color});

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 350,
        height: 280,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isHovered ? widget.color.withOpacity(0.1) : const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isHovered ? widget.color.withOpacity(0.5) : Colors.white10,
            width: 1.5
          ),
          boxShadow: isHovered ? [
             BoxShadow(color: widget.color.withOpacity(0.2), blurRadius: 20, spreadRadius: -5)
          ] : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(widget.icon, color: widget.color, size: 28),
            ),
            const SizedBox(height: 24),
            Text(widget.title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(widget.description, style: const TextStyle(color: Color(0xFF94A3B8), height: 1.5)),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// SECTION: RECRUITMENT & WORKFORCE
// ===========================================================================

class _WorkforceRecruitmentSection extends StatelessWidget {
  const _WorkforceRecruitmentSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F172A).withOpacity(0.5),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 40),
      child: Column(
        children: [
          const _SectionHeader(
            tag: "GLOBAL OPPORTUNITY",
            title: "Earn Money Training AI",
            subtitle: "Join our elite community of annotators. Set your own hours, work from anywhere, and help build the future.",
          ),
          const SizedBox(height: 60),
          
          Wrap(
            spacing: 30,
            runSpacing: 30,
            alignment: WrapAlignment.center,
            children: const [
              _BenefitCard(icon: Icons.payments, title: "Weekly Payouts", desc: "Get paid in USD every week via PayPal or Crypto."),
              _BenefitCard(icon: Icons.schedule, title: "Flexible Schedule", desc: "Work 1 hour or 40 hours. You are your own boss."),
              _BenefitCard(icon: Icons.school, title: "Free Training", desc: "We teach you how to label data for self-driving cars & LLMs."),
            ],
          ),
        ],
      ),
    );
  }
}

class _BenefitCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  const _BenefitCard({required this.icon, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: Colors.blueAccent, size: 30),
          ),
          const SizedBox(height: 20),
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 10),
          Text(desc, style: const TextStyle(color: Colors.white60, height: 1.5)),
        ],
      ),
    );
  }
}

// ===========================================================================
// SECTION: PROCESS WORKFLOW
// ===========================================================================

class _ProcessWorkflowSection extends StatelessWidget {
  const _ProcessWorkflowSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 20),
      child: Column(
        children: [
          const _SectionHeader(
            tag: "WORKFLOW",
            title: "Quality Assurance at Scale",
            subtitle: "Our multi-tiered review process ensures 99.9% accuracy for your training datasets.",
          ),
          const SizedBox(height: 80),
          
          // Responsive layout for steps
          LayoutBuilder(builder: (context, constraints) {
             if (constraints.maxWidth > 900) {
               return Row(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: const [
                   _ProcessStep(number: "01", title: "Upload Data", text: "Securely upload your raw datasets via API."),
                   _ArrowConnector(),
                   _ProcessStep(number: "02", title: "Annotate", text: "Qualified humans label data based on your rules."),
                   _ArrowConnector(),
                   _ProcessStep(number: "03", title: "Audit & QA", text: "Senior reviewers verify quality using consensus."),
                   _ArrowConnector(),
                   _ProcessStep(number: "04", title: "Train Model", text: "Download clean, perfect JSON/CSV outputs."),
                 ],
               );
             } else {
               return Column(
                 children: const [
                    _ProcessStep(number: "01", title: "Upload Data", text: "Securely upload your raw datasets via API."),
                    SizedBox(height: 30),
                    _ProcessStep(number: "02", title: "Annotate", text: "Qualified humans label data based on your rules."),
                    SizedBox(height: 30),
                    _ProcessStep(number: "03", title: "Audit & QA", text: "Senior reviewers verify quality using consensus."),
                    SizedBox(height: 30),
                    _ProcessStep(number: "04", title: "Train Model", text: "Download clean, perfect JSON/CSV outputs."),
                 ],
               );
             }
          }),
        ],
      ),
    );
  }
}

class _ProcessStep extends StatelessWidget {
  final String number;
  final String title;
  final String text;
  const _ProcessStep({required this.number, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Column(
        children: [
          Text(number, style: TextStyle(fontSize: 80, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.05), height: 0.5)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF6366F1), width: 2),
              color: const Color(0xFF6366F1).withOpacity(0.1),
            ),
            child: const Icon(Icons.layers, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 10),
          Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontSize: 14)),
        ],
      ),
    );
  }
}

class _ArrowConnector extends StatelessWidget {
  const _ArrowConnector();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 60), // aligning with icon
      color: Colors.white10,
    );
  }
}

// ===========================================================================
// SECTION: CTA & FOOTER
// ===========================================================================

class _JoinTheTeamCTA extends StatelessWidget {
  const _JoinTheTeamCTA();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 80, horizontal: 20),
      padding: const EdgeInsets.all(50),
      constraints: const BoxConstraints(maxWidth: 1000),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(color: Color(0xFF6366F1), blurRadius: 50, spreadRadius: -20, offset: Offset(0, 10))
        ],
      ),
      child: Column(
        children: [
          const Text("Ready to scale your AI?", style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
          const SizedBox(height: 15),
          const Text(
            "Start your pilot project today. No credit card required for the first 1,000 tasks.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF6366F1),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 22),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Get Started Now", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}

// ===========================================================================
// NEW: NEWSLETTER SECTION
// ===========================================================================

class _NewsletterSection extends StatelessWidget {
  const _NewsletterSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      color: const Color(0xFF020408),
      child: Column(
        children: [
          const Text(
            "STAY UPDATED",
            style: TextStyle(color: Color(0xFFEC4899), fontWeight: FontWeight.bold, letterSpacing: 2),
          ),
          const SizedBox(height: 15),
          Text(
            "Join the DataTricks Community",
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white, fontWeight: FontWeight.bold
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            "Receive the latest updates on AI training, new datasets, and platform features directly in your inbox.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54),
          ),
          const SizedBox(height: 30),
          
          // Email Input & Button
          Container(
            width: 500,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              children: [
                const SizedBox(width: 20),
                const Expanded(
                  child: TextField(
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Enter your email address",
                      hintStyle: TextStyle(color: Colors.white38),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEC4899),
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                  ),
                  child: const Text("Subscribe"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// UPDATED: FOOTER WITH LOGO
// ===========================================================================

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 80, bottom: 40, left: 40, right: 40),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
        color: const Color(0xFF020408),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // UPDATED: BRANDING COLUMN WITH LOGO
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Footer Logo (No animation)
                      Image.asset(
                        'assets/images/logo.png',
                        height: 45,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "DATATRICKS AI", 
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text("The Human Intelligence Layer.", style: TextStyle(color: Colors.white38)),
                ],
              ),
              
              if (MediaQuery.of(context).size.width > 600)
                Row(
                  children: [
                    _FooterColumn(title: "Platform", links: const ["Services", "Pricing", "API Docs"]),
                    const SizedBox(width: 50),
                    _FooterColumn(title: "Company", links: const ["About", "Careers", "Contact"]),
                    const SizedBox(width: 50),
                    _FooterColumn(title: "Legal", links: const ["Privacy", "Terms", "Security"]),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 50),
          const Text("© 2026 DataTricks AI. All rights reserved.", style: TextStyle(color: Colors.white24, fontSize: 12)),
        ],
      ),
    );
  }
}

class _FooterColumn extends StatelessWidget {
  final String title;
  final List<String> links;
  const _FooterColumn({required this.title, required this.links});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        ...links.map((l) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(l, style: const TextStyle(color: Colors.white54, fontSize: 14)),
        )),
      ],
    );
  }
}

// ===========================================================================
// BACKGROUND: GLOBAL CONNECTIVITY PAINTER
// ===========================================================================

class _GlobalNetworkCanvas extends StatelessWidget {
  const _GlobalNetworkCanvas();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(painter: _NetworkPainter()),
    );
  }
}

class _NetworkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF020408);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final gridPaint = Paint()..color = Colors.white.withOpacity(0.03)..strokeWidth = 1;
    for (double i = 0; i < size.width; i += 60) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }

    final nodePaint = Paint()..color = const Color(0xFF6366F1).withOpacity(0.2);
    final random = math.Random(1); 

    for (int i = 0; i < 30; i++) {
      double x = random.nextDouble() * size.width;
      double y = random.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 2, nodePaint);
      
      if (i > 0 && i % 2 == 0) {
         canvas.drawLine(
           Offset(x, y), 
           Offset(random.nextDouble() * size.width, random.nextDouble() * size.height), 
           Paint()..color = const Color(0xFF6366F1).withOpacity(0.05)
         );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ===========================================================================
// UTILITIES AND NAV
// ===========================================================================

class _PrimaryButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;

  const _PrimaryButton({
    required this.text,
    required this.icon,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 10,
        shadowColor: color.withOpacity(0.5),
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  const _AvatarStack();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 40,
      child: Stack(
        children: List.generate(4, (index) {
          return Positioned(
            left: index * 25.0,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF020408),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey[800],
                child: Icon(Icons.person, size: 14, color: Colors.white70),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _PulseConnectivityVisual extends StatefulWidget {
  const _PulseConnectivityVisual();
  @override
  State<_PulseConnectivityVisual> createState() => _PulseConnectivityVisualState();
}

class _PulseConnectivityVisualState extends State<_PulseConnectivityVisual> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(600, 600),
          painter: _OrbPainter(_c.value),
        );
      },
    );
  }
}

class _OrbPainter extends CustomPainter {
  final double progress;
  _OrbPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = const Color(0xFF6366F1).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i < 5; i++) {
      double radius = (100 + (i * 40) + (progress * 50)) % 300;
      double opacity = (1 - (radius / 300)).clamp(0.0, 1.0);
      paint.color = const Color(0xFF6366F1).withOpacity(opacity * 0.5);
      canvas.drawCircle(center, radius, paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// --------------------------------------------------------
// SMOKE / PURPLE FIRE ANIMATION LOGIC
// --------------------------------------------------------

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

// --------------------------------------------------------
// NAVBAR (UPDATED)
// --------------------------------------------------------

class _FixedSmartNavbar extends StatelessWidget {
  final double scrollOffset;
  const _FixedSmartNavbar({required this.scrollOffset});

  @override
  Widget build(BuildContext context) {
    final bool scrolled = scrollOffset > 50;
    
    return Positioned(
      top: 0, left: 0, right: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 120, 
        decoration: BoxDecoration(
          color: scrolled ? const Color(0xFF020408).withOpacity(0.9) : Colors.transparent,
          border: Border(bottom: BorderSide(color: scrolled ? Colors.white10 : Colors.transparent)),
        ),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: Row(
                children: [
                  Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      const Positioned(
                        bottom: 0,
                        child: _SmokeEffect(width: 80, height: 100),
                      ),
                      Image.asset(
                        'assets/images/logo.png',
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  const Text("DATATRICKS AI", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.5, color: Colors.white)),
                  const Spacer(),
                  if (MediaQuery.of(context).size.width > 800) ...[
                    TextButton(onPressed: () {}, child: const Text("For Business", style: TextStyle(color: Colors.white70))),
                    const SizedBox(width: 20),
                    
                    // UPDATED: "For Annotators" button in Navbar
                    TextButton(
                      onPressed: () {
                         Navigator.pushNamed(context, '/careers');
                      }, 
                      child: const Text("For Annotators", style: TextStyle(color: Colors.white70))
                    ),
                    
                    const SizedBox(width: 20),
                  ],
                  const SizedBox(width: 20),
                  
                  // UPDATED: BUTTON CHANGED TO 'GET STARTED' & LINKED
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/auth');
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                    child: const Text("Get started"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String tag;
  final String title;
  final String subtitle;
  const _SectionHeader({required this.tag, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(tag, style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold, letterSpacing: 2)),
        const SizedBox(height: 10),
        Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.displayMedium),
        const SizedBox(height: 15),
        SizedBox(
          width: 600,
          child: Text(subtitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ],
    );
  }
}