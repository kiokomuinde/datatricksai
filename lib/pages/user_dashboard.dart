import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ===========================================================================
// DATATRICKS AI — PORTAL  (Glassmorphism / White Theme)
// Nav: Jobs · Explore · Inbox · Profile · Settings
// No exam flow — Jobs shows opportunity cards with "Submit interest"
// ===========================================================================

// ── COLOUR PALETTE ──────────────────────────────────────────────────────────
const _bgGradientTop = Color(0xFFF8FAFC); // Light slate for visibility
const _bgGradientBot = Color(0xFFE2E8F0); // Slightly darker for glass contrast
const _glassWhite    = Color(0xB3FFFFFF); // 70% opacity white for frosted effect
const _glassBorder   = Color(0xFFFFFFFF); // Pure white glass edges

const _primary       = Color(0xFF3B82F6); // Vibrant Blue
const _primaryLight  = Color(0xFFEFF6FF); // Light Blue
const _primaryMid    = Color(0xFF93C5FD); // Mid Blue
const _secondary     = Color(0xFF10B981); // Bright Green
const _secondaryLight= Color(0xFFD1FAE5); // Light Green
const _green         = Color(0xFF10B981); // Emerald
const _greenLight    = Color(0xFFD1FAE5); // Light Emerald
const _amber         = Color(0xFFF59E0B); // Amber
const _amberLight    = Color(0xFFFEF3C7); // Light Amber
const _red           = Color(0xFFEF4444); // Red
const _redLight      = Color(0xFFFEE2E2); // Light Red
const _textPrimary   = Color(0xFF0F172A); // Dark Slate Text
const _textSecondary = Color(0xFF475569); // Slate Text
const _textMuted     = Color(0xFF94A3B8); // Muted Slate

// ── NAV ─────────────────────────────────────────────────────────────────────
enum _Nav { jobs, explore, inbox, profile, settings }

// ===========================================================================
// OPPORTUNITY MODEL
// ===========================================================================

class _Opp {
  final String id, title, rate, meta, earning;
  final String? description;
  bool submitted;

  _Opp({
    required this.id,
    required this.title,
    required this.rate,
    required this.meta,
    required this.earning,
    this.description,
    this.submitted = false,
  });
}

List<_Opp> _buildOpps() => [
  _Opp(id:'music',   title:'Music Projects Interest Form',                     rate:'\$50–85/hr',  meta:'Remote · Contract', earning:'+ 6K more earning',  submitted: true),
  _Opp(id:'qgis',    title:'Geospatial Analysis (QGIS) Specialists',            rate:'\$125/hr',    description:'Use your expertise and creativity in QGIS to create projects to help train AI',                                                                                         meta:'Remote · Contract', earning:'+ 8K more earning'),
  _Opp(id:'medical', title:'Medical Imaging & 3D Analysis (3D Slicer)',          rate:'\$125/hr',    description:'Use your expertise and creativity in 3D Slicer to create projects to help train AI',                                                                                   meta:'Remote · Contract', earning:'+ 6K more earning'),
  _Opp(id:'para',    title:'Scientific Visualization (ParaView) Specialists',    rate:'\$125/hr',    description:'Use your expertise and creativity in ParaView to create projects to help train AI',                                                                                     meta:'Remote · Contract', earning:'+ 5K more earning',  submitted: true),
  _Opp(id:'video',   title:'Video Production Specialists',                       rate:'\$125/hr',    description:'Use your expertise and creativity in Lightworks, Shotcut, or OpenShot to create projects to help train AI',                                                              meta:'Remote · Contract', earning:'+ 11K more earning', submitted: true),
  _Opp(id:'game',    title:'Game Development Specialists',                       rate:'\$125/hr',    description:'Use your expertise and creativity in Godot, Defold, Solar 3D, Panda 3D or Stride (Xenko) to create projects to help train AI',                                          meta:'Remote · Contract', earning:'+ 13K more earning'),
  _Opp(id:'media',   title:'2D & 3D Digital Media Specialists',                  rate:'\$125/hr',    description:'Use your expertise and creativity in GIMP, Inkscape, Krita, Libresprite, or Blender to create projects to help train AI',                                               meta:'Remote · Contract', earning:'+ 7K more earning'),
  _Opp(id:'eda',     title:'Electronics Design & Simulation (EDA Tools)',        rate:'\$125/hr',    description:'Use your experience and creativity in KiCAD, LibrePCB, Qucs-s and Ngspice tools to help train AI',                                                                     meta:'Remote · Contract', earning:'+ 3K more earning'),
  _Opp(id:'llm',     title:'LLM Response Quality Evaluator',                     rate:'\$18–25/hr',  description:'Evaluate AI-generated responses for quality, accuracy, and helpfulness to improve model performance.',                                                                  meta:'Remote · Contract', earning:'+ 9K more earning'),
  _Opp(id:'annot',   title:'Data Annotation Specialist',                         rate:'\$15–20/hr',  description:'Label and categorize datasets to train machine learning models with high precision.',                                                                                   meta:'Remote · Contract', earning:'+ 4K more earning'),
  _Opp(id:'safety',  title:'AI Safety & Alignment Reviewer',                     rate:'\$25–35/hr',  description:'Identify harmful, biased, or unsafe AI outputs to improve model safety and alignment.',                                                                                meta:'Remote · Contract', earning:'+ 5K more earning'),
  _Opp(id:'write',   title:'Creative Writing Quality Reviewer',                  rate:'\$20–30/hr',  description:'Assess AI-generated creative content for originality, style, and overall coherence.',                                                                                  meta:'Remote · Contract', earning:'+ 6K more earning'),
];

// ===========================================================================
// GLASSMORPHISM HELPER COMPONENT
// ===========================================================================

class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final Color? color;
  final BoxBorder? border;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin = EdgeInsets.zero,
    this.borderRadius = 12,
    this.color,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color: color ?? _glassWhite,
                borderRadius: BorderRadius.circular(borderRadius),
                border: border ?? Border.all(color: _glassBorder, width: 1.5),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// ROOT WIDGET
// ===========================================================================

class UserDashboard extends StatefulWidget {
  final String userEmail;
  const UserDashboard({super.key, required this.userEmail});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> with TickerProviderStateMixin {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String? _error;

  _Nav _active = _Nav.jobs;
  bool _navExpanded = true;

  late AnimationController _navAnim;
  late Animation<double>   _navWidth;

  late List<_Opp> _opps;

  @override
  void initState() {
    super.initState();
    _opps = _buildOpps();
    _navAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));
    _navWidth = Tween<double>(begin: 60, end: 220).animate(
      CurvedAnimation(parent: _navAnim, curve: Curves.easeInOut)
    );
    _navAnim.forward();
    _loadUser();
  }

  @override
  void dispose() { 
    _navAnim.dispose(); 
    super.dispose(); 
  }

  void _toggleNav() {
    setState(() {
      _navExpanded = !_navExpanded;
      _navExpanded ? _navAnim.forward() : _navAnim.reverse();
    });
  }

  Future<void> _loadUser() async {
    try {
      final q = await FirebaseFirestore.instance
          .collection('applications')
          .where('email', isEqualTo: widget.userEmail)
          .limit(1).get();
      if (q.docs.isNotEmpty) {
        setState(() { 
          _userData = q.docs.first.data(); 
          _isLoading = false; 
        });
      } else {
        setState(() { 
          _error = 'No application found.'; 
          _isLoading = false; 
        });
      }
    } catch (_) {
      setState(() { 
        _error = 'Failed to load profile.'; 
        _isLoading = false; 
      });
    }
  }

  void _logout() => Navigator.pushNamedAndRemoveUntil(context, '/auth', (_) => false);

  void _submitInterest(_Opp opp) {
    setState(() => opp.submitted = true);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Interest submitted for "${opp.title}"'),
      backgroundColor: _primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const _Loader();
    if (_error != null) return _ErrorView(error: _error!, onBack: _logout);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_bgGradientTop, _bgGradientBot],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        ),
        child: Row(children: [
          // ── Sidebar ──
          AnimatedBuilder(
            animation: _navWidth,
            builder: (_, __) => _Sidebar(
              width: _navWidth.value,
              expanded: _navExpanded,
              active: _active,
              onTap: (n) => setState(() => _active = n),
              onToggle: _toggleNav,
              userData: _userData,
              onLogout: _logout,
              userEmail: widget.userEmail,
            ),
          ),
          // ── Main ──
          Expanded(child: Column(children: [
            _TopBar(active: _active, userData: _userData, onMenuTap: _toggleNav),
            Expanded(child: _body()),
          ])),
        ]),
      ),
    );
  }

  Widget _body() {
    switch (_active) {
      case _Nav.jobs:
        return _JobsPage(opps: _opps, onSubmit: _submitInterest, userEmail: widget.userEmail);
      case _Nav.explore:
        return _ExplorePage(opps: _opps, onSubmit: _submitInterest);
      case _Nav.inbox:
        return const _InboxPage();
      case _Nav.profile:
        return _ProfilePage(userData: _userData!, userEmail: widget.userEmail);
      case _Nav.settings:
        return const _SettingsPage();
    }
  }
}

// ===========================================================================
// SIDEBAR 
// ===========================================================================

class _Sidebar extends StatelessWidget {
  final double width;
  final bool expanded;
  final _Nav active;
  final ValueChanged<_Nav> onTap;
  final VoidCallback onToggle;
  final Map<String, dynamic>? userData;
  final VoidCallback onLogout;
  final String userEmail;

  const _Sidebar({
    required this.width, 
    required this.expanded, 
    required this.active,
    required this.onTap, 
    required this.onToggle,
    required this.userData, 
    required this.onLogout,
    required this.userEmail,
  });

  static const _items = [
    (_Nav.jobs,     Icons.work_outline_rounded,    'Jobs'),
    (_Nav.explore,  Icons.explore_outlined,        'Explore'),
    (_Nav.inbox,    Icons.mail_outline_rounded,    'Inbox'),
    (_Nav.profile,  Icons.person_outline_rounded,  'Profile'),
    (_Nav.settings, Icons.settings_outlined,       'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final firstName = userData?['firstName'] ?? '';
    final initials  = firstName.isNotEmpty ? firstName[0].toUpperCase() : '?';

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeInOut,
          width: width,
          decoration: BoxDecoration(
            color: _glassWhite,
            border: const Border(right: BorderSide(color: _glassBorder, width: 1.5)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(2, 0))
            ],
          ),
          child: Column(children: [
            // Logo Section updated to Landing Page Logo
            GestureDetector(
              onTap: onToggle,
              child: Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.centerLeft,
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _glassBorder, width: 1.5))),
                child: Row(children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 36,
                    width: 36,
                    fit: BoxFit.contain,
                  ),
                  if (expanded) ...[
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'DATATRICKS AI', 
                        style: TextStyle(
                          color: _textPrimary, 
                          fontWeight: FontWeight.w900, 
                          fontSize: 14, 
                          letterSpacing: -0.2
                        )
                      )
                    ),
                  ],
                ]),
              ),
            ),

            // Nav items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                children: [
                  ..._items.map((item) {
                    final active = this.active == item.$1;
                    return _SidebarItem(
                      icon: item.$2, 
                      label: item.$3,
                      isActive: active, 
                      expanded: expanded,
                      onTap: () => onTap(item.$1),
                    );
                  }),
                  const SizedBox(height: 8),
                  // Share button in sidebar
                  Builder(builder: (ctx) => GestureDetector(
                    onTap: () => _shareCareerLink(ctx, userEmail),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: EdgeInsets.symmetric(horizontal: expanded ? 12 : 0, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3)),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.share_rounded, color: Colors.white, size: 17),
                          if (expanded) ...[
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Share & Earn',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )),
                ],
              ),
            ),

            // User footer
            const Divider(color: _glassBorder, height: 1, thickness: 1.5),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(children: [
                Container(
                  width: 34, height: 34,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primary, _secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)
                    )
                  ),
                ),
                if (expanded) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, 
                      children: [
                        Text(
                          firstName, 
                          style: const TextStyle(color: _textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis
                        ),
                        Text(
                          userData?['email'] ?? '', 
                          style: const TextStyle(color: _textMuted, fontSize: 10),
                          overflow: TextOverflow.ellipsis
                        ),
                      ]
                    )
                  ),
                  IconButton(
                    onPressed: onLogout,
                    icon: const Icon(Icons.logout_rounded, color: _textMuted, size: 16),
                    tooltip: 'Logout', 
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                  ),
                ],
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive, expanded;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon, 
    required this.label, 
    required this.isActive,
    required this.expanded, 
    required this.onTap
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: EdgeInsets.symmetric(horizontal: expanded ? 12 : 10, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? _primaryLight.withOpacity(0.8) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        Icon(icon, color: isActive ? _primary : _textMuted, size: 20),
        if (expanded) ...[
          const SizedBox(width: 12),
          Text(label, style: TextStyle(
            color: isActive ? _primary : _textSecondary,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            fontSize: 14,
          )),
        ],
      ]),
    ),
  );
}

// ===========================================================================
// TOP BAR
// ===========================================================================

class _TopBar extends StatelessWidget {
  final _Nav active;
  final Map<String, dynamic>? userData;
  final VoidCallback onMenuTap;

  const _TopBar({
    required this.active, 
    required this.userData, 
    required this.onMenuTap
  });

  static const _titles = {
    _Nav.jobs:     'Jobs',
    _Nav.explore:  'Explore',
    _Nav.inbox:    'Inbox',
    _Nav.profile:  'My Profile',
    _Nav.settings: 'Settings',
  };

  @override
  Widget build(BuildContext context) {
    final status = userData?['status'] ?? 'pending';
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: const BoxDecoration(
            color: _glassWhite,
            border: Border(bottom: BorderSide(color: _glassBorder, width: 1.5)),
          ),
          child: Row(children: [
            Text(
              _titles[active]!, 
              style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.w700, fontSize: 17)
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => _showPendingReviewPopup(context),
              child: _StatusChip(status: status),
            ),
            const SizedBox(width: 10),
            _IBtn(icon: Icons.notifications_none_rounded, onTap: () {}),
          ]),
        ),
      ),
    );
  }
}

class _IBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  
  const _IBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 34, height: 34,
      decoration: BoxDecoration(
        color: _glassWhite, 
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _glassBorder, width: 1.5)
      ),
      child: Icon(icon, color: _textSecondary, size: 17),
    ),
  );
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _sc(status);
    final bg    = _sb(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg, 
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3))
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(_sl(status), style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

Color  _sc(String? s) { 
  switch(s) {
    case 'approved': return _green;
    case 'rejected': return _red;
    case 'reviewing': return _amber;
    default: return _primary;
  } 
}

Color  _sb(String? s) { 
  switch(s) {
    case 'approved': return _greenLight;
    case 'rejected': return _redLight;
    case 'reviewing': return _amberLight;
    default: return _primaryLight;
  } 
}

String _sl(String? s) { 
  switch(s) {
    case 'approved': return 'Approved';
    case 'rejected': return 'Not Selected';
    case 'reviewing': return 'Under Review';
    default: return 'Pending Review';
  } 
}

// ===========================================================================
// PENDING REVIEW POPUP
// ===========================================================================

void _showPendingReviewPopup(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black.withOpacity(0.55),
    transitionDuration: const Duration(milliseconds: 320),
    transitionBuilder: (_, anim, __, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
      return ScaleTransition(
        scale: Tween<double>(begin: 0.82, end: 1.0).animate(curved),
        child: FadeTransition(opacity: anim, child: child),
      );
    },
    pageBuilder: (ctx, _, __) => Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 380,
          margin: const EdgeInsets.symmetric(horizontal: 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: _amber.withOpacity(0.25), blurRadius: 40, spreadRadius: 4, offset: const Offset(0, 12)),
              BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 20, offset: const Offset(0, 6)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Gradient header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFF7E6), Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    // Animated pulse icon
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            color: _amber.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 62, height: 62,
                          decoration: BoxDecoration(
                            color: _amber.withOpacity(0.25),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 46, height: 46,
                          decoration: const BoxDecoration(
                            color: _amber,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.shield_outlined, color: Colors.white, size: 24),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Pending Review',
                      style: TextStyle(
                        color: Color(0xFF92400E),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              // Body
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
                child: Column(
                  children: [
                    // Warning banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _amber.withOpacity(0.4), width: 1.5),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded, color: _amber, size: 20),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Persona Verification is Missing',
                              style: TextStyle(
                                color: Color(0xFF92400E),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Your account is currently under review. To unlock full access and start earning, please complete your persona verification.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 13,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Steps
                    _PopupStep(
                      number: '1',
                      label: 'Complete persona verification',
                      color: _primary,
                    ),
                    const SizedBox(height: 10),
                    _PopupStep(
                      number: '2',
                      label: 'Await approval from our HR team. For any approval enquiries, please contact hr@datatricksai.us',
                      color: _secondary,
                    ),
                    const SizedBox(height: 28),
                    // CTA button
                    SizedBox(
                      width: double.infinity,
                      child: GestureDetector(
                        onTap: () => Navigator.of(ctx).pop(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_amber, Color(0xFFF97316)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(color: _amber.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.verified_user_rounded, color: Colors.white, size: 17),
                              SizedBox(width: 8),
                              Text(
                                'Got it',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _PopupStep extends StatelessWidget {
  final String number, label;
  final Color color;
  const _PopupStep({required this.number, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      width: 26, height: 26,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Center(
        child: Text(number, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
      ),
    ),
    const SizedBox(width: 12),
    Expanded(
      child: Text(label, style: const TextStyle(color: _textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
    ),
  ]);
}

// ===========================================================================
// SHARE & EARN — REFERRAL COPY POPUP
// ===========================================================================

const _careersUrl = 'https://datatricksai.us/careers';

String _buildReferralMessage(String userEmail) =>
    '🚀 Exciting Opportunity — Join DataTricks AI!\n\n'
    'I\'m working on cutting-edge AI data projects with DataTricks AI and thought you\'d be a great fit. '
    'They\'re hiring talented professionals for remote contract roles with competitive hourly rates.\n\n'
    '👉 Apply here: $_careersUrl\n\n'
    '📝 IMPORTANT: When filling out the application form, please enter my DataTricks account email '
    'in the referral field — this ensures we\'re both recognised for the partnership.\n\n'
    'My referral email: $userEmail\n\n'
    'Looking forward to working alongside you!';

void _shareCareerLink(BuildContext context, String userEmail) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black.withOpacity(0.60),
    transitionDuration: const Duration(milliseconds: 340),
    transitionBuilder: (_, anim, __, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
      return ScaleTransition(
        scale: Tween<double>(begin: 0.80, end: 1.0).animate(curved),
        child: FadeTransition(opacity: anim, child: child),
      );
    },
    pageBuilder: (ctx, _, __) => _ReferralDialog(userEmail: userEmail),
  );
}

class _ReferralDialog extends StatefulWidget {
  final String userEmail;
  const _ReferralDialog({required this.userEmail});

  @override
  State<_ReferralDialog> createState() => _ReferralDialogState();
}

class _ReferralDialogState extends State<_ReferralDialog> {
  bool _copied = false;

  void _handleCopy() async {
    await Clipboard.setData(ClipboardData(text: _buildReferralMessage(widget.userEmail)));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final screenW  = MediaQuery.of(context).size.width;
    final screenH  = MediaQuery.of(context).size.height;
    final isMobile = screenW < 600;
    final dialogW  = isMobile ? screenW * 0.94 : 400.0;
    final hPad     = isMobile ? 18.0 : 24.0;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: dialogW,
            maxHeight: screenH * 0.88,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.20),
                  blurRadius: 40,
                  spreadRadius: 2,
                  offset: const Offset(0, 14),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                // ── Gradient Header ────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(hPad, 22, hPad, 20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFF06B6D4)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Decorative orb
                      Positioned(
                        right: -8, top: -8,
                        child: Container(
                          width: 70, height: 70,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.07),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Share & Earn',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.20),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    '\$300 per successful referral',
                                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close_rounded, color: Colors.white, size: 15),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Scrollable Body ────────────────────────────────────
                Flexible(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(hPad, 18, hPad, 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // Terms label
                        const Text(
                          'REFERRAL TERMS',
                          style: TextStyle(
                            color: _textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Term rows — compact inline style
                        _ReferralTerm(
                          icon: Icons.monetization_on_rounded,
                          iconColor: const Color(0xFF10B981),
                          iconBg: const Color(0xFFD1FAE5),
                          title: '\$300 reward',
                          body: 'Earned for every person you refer who qualifies.',
                        ),
                        const SizedBox(height: 8),
                        _ReferralTerm(
                          icon: Icons.timer_rounded,
                          iconColor: const Color(0xFF3B82F6),
                          iconBg: const Color(0xFFEFF6FF),
                          title: '10 hrs minimum',
                          body: 'Referral qualifies after account creation + 10 hours of paid work.',
                        ),
                        const SizedBox(height: 8),
                        _ReferralTerm(
                          icon: Icons.alternate_email_rounded,
                          iconColor: const Color(0xFF8B5CF6),
                          iconBg: const Color(0xFFF5F3FF),
                          title: 'Add your email',
                          body: 'Referee must enter your DataTricks account email on the application form.',
                        ),

                        const SizedBox(height: 20),

                        // ── Copy Button ────────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          child: GestureDetector(
                            onTap: _copied ? null : _handleCopy,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                gradient: _copied
                                    ? const LinearGradient(
                                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      )
                                    : const LinearGradient(
                                        colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: (_copied
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFF4F46E5))
                                        .withOpacity(0.30),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    child: Icon(
                                      _copied ? Icons.check_circle_rounded : Icons.copy_rounded,
                                      color: Colors.white,
                                      size: 17,
                                      key: ValueKey(_copied),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    child: Text(
                                      _copied ? 'Copied!' : 'Copy Invite Link',
                                      key: ValueKey(_copied),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                      ),
                                    ),
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
          ),
        ),
      ),
    );
  }
}

class _ReferralTerm extends StatelessWidget {
  final IconData icon;
  final Color iconColor, iconBg;
  final String title, body;

  const _ReferralTerm({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFFAFAFC),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFE8ECF0), width: 1.2),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$title  ',
                  style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.w700, fontSize: 12),
                ),
                TextSpan(
                  text: body,
                  style: const TextStyle(color: _textSecondary, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _ShareBanner extends StatelessWidget {
  final String userEmail;
  const _ShareBanner({required this.userEmail});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFF06B6D4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 6)),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -18, top: -18,
            child: Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 30, bottom: -28,
            child: Container(
              width: 70, height: 70,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(children: [
              // Icon badge
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.people_alt_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Share with Friends & Earn',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: -0.2),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Invite friends to apply for AI projects',
                      style: TextStyle(color: Colors.white.withOpacity(0.78), fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _shareCareerLink(context, userEmail),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: const [
                    Icon(Icons.card_giftcard_rounded, color: Color(0xFF6366F1), size: 15),
                    SizedBox(width: 6),
                    Text('Refer & Earn', style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.w800, fontSize: 12)),
                  ]),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// JOBS PAGE
// ===========================================================================

class _JobsPage extends StatelessWidget {
  final List<_Opp> opps;
  final void Function(_Opp) onSubmit;
  final String userEmail;

  const _JobsPage({required this.opps, required this.onSubmit, required this.userEmail});

  @override
  Widget build(BuildContext context) {
    final open = opps.take(8).toList(); // first 8 as "open"

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Earnings strip
        const _EarningsStrip(),
        const SizedBox(height: 20),

        // Share with friends CTA
        _ShareBanner(userEmail: userEmail),
        const SizedBox(height: 28),

        // Opportunities
        const Text('Open opportunities', style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w700, fontSize: 17)),
        const SizedBox(height: 14),
        _OppGrid(opps: open, onSubmit: onSubmit),
      ]),
    );
  }
}
class _EarningsStrip extends StatelessWidget {
  const _EarningsStrip();
  
  @override
  Widget build(BuildContext context) => GlassContainer(
    padding: const EdgeInsets.all(20),
    child: Column(children: [
      Row(children: const [
        _EStat(label: 'Awaiting payout', value: '\$0.00'),
        SizedBox(width: 40),
        _EStat(label: 'Total paid', value: '\$0.00'),
      ]),
      const SizedBox(height: 18),
      Row(children: const [
        _EStat(label: 'Tasks this week', value: '0'),
        SizedBox(width: 40),
        _EStat(label: 'Hours this week', value: '0:00'),
      ]),
    ]),
  );
}

class _EStat extends StatelessWidget {
  final String label, value;
  
  const _EStat({required this.label, required this.value});
  
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: _textMuted, fontSize: 13)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: _textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
      ],
    ),
  );
}

// ===========================================================================
// EXPLORE PAGE
// ===========================================================================

class _ExplorePage extends StatefulWidget {
  final List<_Opp> opps;
  final void Function(_Opp) onSubmit;

  const _ExplorePage({required this.opps, required this.onSubmit});

  @override
  State<_ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<_ExplorePage> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.opps
        .where((o) => o.title.toLowerCase().contains(_q.toLowerCase()) || 
                     (o.description?.toLowerCase().contains(_q.toLowerCase()) ?? false))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Explore opportunities', style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w700, fontSize: 17)),
        const SizedBox(height: 14),
        
        // Search
        GlassContainer(
          padding: EdgeInsets.zero,
          child: TextField(
            onChanged: (v) => setState(() => _q = v),
            style: const TextStyle(color: _textPrimary, fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'Search opportunities...',
              hintStyle: TextStyle(color: _textMuted, fontSize: 14),
              prefixIcon: Icon(Icons.search_rounded, color: _textMuted, size: 20),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 20),
        
        _OppGrid(opps: filtered, onSubmit: widget.onSubmit),
      ]),
    );
  }
}

// ===========================================================================
// OPPORTUNITY GRID
// ===========================================================================

class _OppGrid extends StatelessWidget {
  final List<_Opp> opps;
  final void Function(_Opp) onSubmit;

  const _OppGrid({required this.opps, required this.onSubmit});

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (_, c) {
    final cols = c.maxWidth > 700 ? 2 : 1;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: opps.map((opp) {
        final w = (c.maxWidth - (cols - 1) * 12) / cols;
        return SizedBox(width: w, child: _OppCard(opp: opp, onSubmit: () => onSubmit(opp)));
      }).toList(),
    );
  });
}

class _OppCard extends StatelessWidget {
  final _Opp opp;
  final VoidCallback onSubmit;

  const _OppCard({required this.opp, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  opp.title, 
                  style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.w700, fontSize: 15)
                )
              ),
              const SizedBox(width: 10),
              Text(
                opp.rate, 
                style: const TextStyle(color: _primary, fontWeight: FontWeight.w700, fontSize: 14)
              ),
            ]
          ),
          const SizedBox(height: 8),
          Text(opp.meta, style: const TextStyle(color: _textMuted, fontSize: 12)),
          
          if (opp.description != null) ...[
            const SizedBox(height: 12),
            Text(
              opp.description!, 
              style: const TextStyle(color: _textSecondary, fontSize: 13, height: 1.4), 
              maxLines: 2, 
              overflow: TextOverflow.ellipsis
            ),
          ],
          
          const SizedBox(height: 20),
          const Divider(color: _glassBorder, thickness: 1.5),
          const SizedBox(height: 12),
          
          Row(
            children: [
              // Decorative circles using the new Blue & Green palettes
              SizedBox(
                width: 64, height: 24,
                child: Stack(children: [
                  for (int i = 0; i < 3; i++)
                    Positioned(
                      left: i * 18.0,
                      child: Container(
                        width: 24, height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: [_primaryMid, _secondaryLight, _greenLight][i],
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ]),
              ),
              const SizedBox(width: 6),
              Text(opp.earning, style: const TextStyle(color: _textMuted, fontSize: 12)),
              const Spacer(),
              
              // CTA Button integrated with primary color
              if (opp.submitted)
                Row(mainAxisSize: MainAxisSize.min, children: const [
                  Icon(Icons.check_rounded, color: _primary, size: 15),
                  SizedBox(width: 4),
                  Text('Submitted', style: TextStyle(color: _primary, fontWeight: FontWeight.w700, fontSize: 13)),
                ])
              else
                GestureDetector(
                  onTap: onSubmit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _primary, 
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(color: _primary.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))
                      ],
                    ),
                    child: const Text('Submit interest', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                  ),
                ),
            ]
          )
        ]
      )
    );
  }
}

// ===========================================================================
// INBOX PAGE
// ===========================================================================

class _InboxPage extends StatelessWidget {
  const _InboxPage();

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(28),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Inbox', style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w700, fontSize: 17)),
      const SizedBox(height: 20),
      
      const _MsgTile(
        sender: 'DataTricks Recruitment', 
        icon: Icons.business_rounded, 
        iconColor: _primary, 
        time: '5 days ago', 
        preview: 'Thank you for applying! We have received your application and will be in touch shortly.', 
        unread: true
      ),
      const SizedBox(height: 10),
      const _MsgTile(
        sender: 'System Notification', 
        icon: Icons.notifications_rounded, 
        iconColor: _secondary, 
        time: '5 days ago', 
        preview: 'Your account has been created. Welcome to the DataTricks AI platform.', 
        unread: false
      ),
    ]),
  );
}

class _MsgTile extends StatelessWidget {
  final String sender;
  final IconData icon;
  final Color iconColor;
  final String time;
  final String preview;
  final bool unread;

  const _MsgTile({
    required this.sender, 
    required this.icon, 
    required this.iconColor, 
    required this.time, 
    required this.preview, 
    this.unread = false
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      color: unread ? _primaryLight.withOpacity(0.6) : _glassWhite,
      border: Border.all(color: unread ? _primary.withOpacity(0.3) : _glassBorder, width: 1.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1), 
              borderRadius: BorderRadius.circular(8)
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      sender, 
                      style: TextStyle(color: _textPrimary, fontWeight: unread ? FontWeight.bold : FontWeight.w600, fontSize: 14)
                    ),
                    Text(time, style: const TextStyle(color: _textMuted, fontSize: 11)),
                  ]
                ),
                const SizedBox(height: 6),
                Text(
                  preview, 
                  style: const TextStyle(color: _textSecondary, fontSize: 13, height: 1.4), 
                  maxLines: 2, 
                  overflow: TextOverflow.ellipsis
                ),
              ]
            )
          )
        ]
      )
    );
  }
}

// ===========================================================================
// PROFILE PAGE
// ===========================================================================

class _ProfilePage extends StatelessWidget {
  final Map<String, dynamic> userData;
  final String userEmail;
  const _ProfilePage({required this.userData, required this.userEmail});

  @override
  Widget build(BuildContext context) {
    final firstName = userData['firstName'] ?? '';
    final lastName = userData['lastName'] ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        
        // Hero banner 
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_primary, _secondary],
              begin: Alignment.topLeft, 
              end: Alignment.bottomRight
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: _primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 6))
            ],
          ),
          child: Row(children: [
            Container(
              width: 68, height: 68, 
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle), 
              child: Center(
                child: Text(
                  firstName.isNotEmpty ? firstName[0].toUpperCase() : '?', 
                  style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800)
                )
              )
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  Text(
                    '$firstName $lastName', 
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)
                  ),
                  const SizedBox(height: 3),
                  Text(
                    userData['email'] ?? '', 
                    style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13)
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => _showPendingReviewPopup(context),
                    child: _StatusChip(status: userData['status'] ?? 'pending'),
                  ),
                ]
              )
            ),
          ]),
        ),
        const SizedBox(height: 20),

        LayoutBuilder(builder: (_, c) {
          final personal = _InfoCard(
            title: 'Personal Information', 
            icon: Icons.person_outline_rounded, 
            rows: [
              _IRow(label: 'Full Name', value: '$firstName $lastName'),
              _IRow(label: 'Email', value: userData['email'] ?? '—'),
              _IRow(label: 'Phone', value: userData['phone'] ?? '—'),
              _IRow(label: 'Date of Birth', value: userData['dob'] ?? '—'),
            ]
          );

          final professional = _InfoCard(
            title: 'Professional Details', 
            icon: Icons.work_outline_rounded, 
            rows: [
              _IRow(label: 'Experience', value: userData['experience'] ?? '—'),
              _IRow(label: 'Skills', value: userData['skills'] ?? '—'),
              _IRow(label: 'Availability', value: userData['availability'] ?? '—'),
            ],
            extra: const [
              SizedBox(height: 10),
              Divider(color: _glassBorder, thickness: 1.5),
              SizedBox(height: 10),
              _DocRow(label: 'Resume / CV', fileName: 'Resume.pdf'),
            ]
          );

          if (c.maxWidth > 600) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: personal),
                const SizedBox(width: 20),
                Expanded(child: professional),
              ]
            );
          } else {
            return Column(
              children: [
                personal,
                const SizedBox(height: 20),
                professional,
              ]
            );
          }
        }),
        const SizedBox(height: 20),
        _ShareBanner(userEmail: userEmail),
      ]),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_IRow> rows;
  final List<Widget> extra;
  
  const _InfoCard({required this.title, required this.icon, required this.rows, this.extra = const []});
  
  @override
  Widget build(BuildContext context) => GlassContainer(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, 
      children: [
        Row(children: [
          Container(
            width: 28, height: 28, 
            decoration: BoxDecoration(color: _primaryLight, borderRadius: BorderRadius.circular(6)), 
            child: Icon(icon, color: _primary, size: 14)
          ),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
        const SizedBox(height: 6),
        const Divider(color: _glassBorder, thickness: 1.5),
        const SizedBox(height: 6),
        ...rows,
        ...extra,
      ]
    ),
  );
}

class _IRow extends StatelessWidget {
  final String label, value;
  const _IRow({required this.label, required this.value});
  
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start, 
      children: [
        SizedBox(width: 130, child: Text(label, style: const TextStyle(color: _textMuted, fontSize: 12))),
        Expanded(
          child: Text(
            value.isNotEmpty ? value : '—', 
            style: const TextStyle(color: _textPrimary, fontSize: 12, fontWeight: FontWeight.w500)
          )
        ),
      ]
    ),
  );
}

class _DocRow extends StatelessWidget {
  final String label, fileName;
  final String? url;
  
  const _DocRow({required this.label, required this.fileName, this.url});
  
  @override
  Widget build(BuildContext context) => Row(children: [
    const Icon(Icons.insert_drive_file_outlined, color: _primary, size: 18),
    const SizedBox(width: 10),
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Text(label, style: const TextStyle(color: _textMuted, fontSize: 11)),
          Text(fileName, style: const TextStyle(color: _textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
        ]
      )
    ),
  ]);
}

// ===========================================================================
// SETTINGS PAGE
// ===========================================================================

class _SettingsPage extends StatelessWidget {
  const _SettingsPage();

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(28),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Settings', style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w700, fontSize: 17)),
      const SizedBox(height: 20),

      // Verification status banner
      GlassContainer(
        padding: const EdgeInsets.all(20),
        color: const Color(0xFFFFFBEB),
        border: Border.all(color: _amber.withOpacity(0.35), width: 1.5),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: _amber.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield_outlined, color: _amber, size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Persona Verification', style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
                SizedBox(height: 2),
                Text('Your identity verification is pending review', style: TextStyle(color: _textMuted, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Builder(builder: (ctx) => GestureDetector(
            onTap: () => _showPendingReviewPopup(ctx),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _amber,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: _amber.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: const [
                Icon(Icons.timelapse_rounded, color: Colors.white, size: 13),
                SizedBox(width: 5),
                Text('Pending Review', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11)),
              ]),
            ),
          )),
        ]),
      ),
      const SizedBox(height: 16),

      const _SSection(title: 'Notifications', children: [
        _STgl(label: 'Email Alerts', subtitle: 'Receive daily updates on new opportunities', initial: true),
        _STgl(label: 'Push Notifications', subtitle: 'Instant alerts for application status changes', initial: true),
      ]),
      const SizedBox(height: 16),
      
      const _SSection(title: 'Privacy', children: [
        _STgl(label: 'Profile Visibility', subtitle: 'Allow recruiters to view your full profile', initial: true),
        _STgl(label: 'Online Status', subtitle: 'Let others see when you\'re active', initial: false),
      ]),
    ]),
  );
}

class _SSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  
  const _SSection({required this.title, required this.children});
  
  @override
  Widget build(BuildContext context) => GlassContainer(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, 
      children: [
        Text(title, style: const TextStyle(color: _primary, fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.3)),
        const SizedBox(height: 10),
        ...children,
      ]
    ),
  );
}


class _STgl extends StatefulWidget {
  final String label, subtitle;
  final bool initial;
  
  const _STgl({required this.label, required this.subtitle, required this.initial});
  
  @override
  State<_STgl> createState() => _STglState();
}

class _STglState extends State<_STgl> {
  late bool val;
  
  @override
  void initState() { 
    super.initState(); 
    val = widget.initial; 
  }
  
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.label, style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 2),
              Text(widget.subtitle, style: const TextStyle(color: _textMuted, fontSize: 11)),
            ]
          )
        ),
        Switch(
          value: val,
          onChanged: (v) => setState(() => val = v),
          activeColor: _primary,
        )
      ]
    ),
  );
}

// ===========================================================================
// LOADERS AND ERROR VIEWS
// ===========================================================================

class _Loader extends StatelessWidget {
  const _Loader();
  
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_bgGradientTop, _bgGradientBot],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        )
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, 
          children: const [
            CircularProgressIndicator(color: _primary, strokeWidth: 2.5),
            SizedBox(height: 16),
            Text('Loading...', style: TextStyle(color: _textSecondary, fontSize: 14)),
          ]
        )
      ),
    ),
  );
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onBack;
  
  const _ErrorView({required this.error, required this.onBack});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_bgGradientTop, _bgGradientBot],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        )
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, 
          children: [
            Container(
              width: 54, height: 54,
              decoration: const BoxDecoration(color: _redLight, shape: BoxShape.circle),
              child: const Icon(Icons.error_outline_rounded, color: _red, size: 26)
            ),
            const SizedBox(height: 14),
            Text(error, style: const TextStyle(color: _textSecondary, fontSize: 14)),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onBack,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(8)),
                child: const Text('Go Back', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ]
        )
      ),
    ),
  );
}