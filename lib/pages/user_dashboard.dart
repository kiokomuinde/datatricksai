import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Page Views
import 'dashboard_page.dart';
import 'explore_page.dart';
import 'onboarding_exam_page.dart';
import 'payments_page.dart';
import 'profile_page.dart';
import 'settings_page.dart';

// Split Components housed in dashboard_user/
import 'dashboard_user/theme_constants.dart';
import 'dashboard_user/opportunity_model.dart';
import 'dashboard_user/glass_container.dart';
import 'dashboard_user/app_dialogs.dart';

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
  String? _docId;                          
  bool _isLoading = true;
  String? _error;

  StreamSubscription<QuerySnapshot>? _userSub; 

  AppNav _active = AppNav.jobs;
  bool _navExpanded = true;

  late AnimationController _navAnim;
  late Animation<double>   _navWidth;

  late List<Opp> _opps;

  @override
  void initState() {
    super.initState();
    _opps = buildOpps();
    _navAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));
    _navWidth = Tween<double>(begin: 60, end: 220).animate(
      CurvedAnimation(parent: _navAnim, curve: Curves.easeInOut),
    );
    _navAnim.forward();
    _subscribeUser();
  }

  @override
  void dispose() {
    _userSub?.cancel();  
    _navAnim.dispose();
    super.dispose();
  }

  void _toggleNav() {
    setState(() {
      _navExpanded = !_navExpanded;
      _navExpanded ? _navAnim.forward() : _navAnim.reverse();
    });
  }

  void _subscribeUser() {
    _userSub = FirebaseFirestore.instance
        .collection('applications')
        .where('email', isEqualTo: widget.userEmail)
        .limit(1)
        .snapshots()
        .listen(
      (snapshot) {
        if (!mounted) return;
        if (snapshot.docs.isNotEmpty) {
          setState(() {
            _docId    = snapshot.docs.first.id;      
            _userData = snapshot.docs.first.data();
            _isLoading = false;
            _error     = null;
          });
        } else {
          setState(() { _error = 'No application found.'; _isLoading = false; });
        }
      },
      onError: (_) {
        if (!mounted) return;
        setState(() { _error = 'Failed to load profile.'; _isLoading = false; });
      },
    );
  }

  void _logout() => Navigator.pushNamedAndRemoveUntil(context, '/auth', (_) => false);

  void _submitInterest(Opp opp) {
    setState(() => opp.submitted = true);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Interest submitted for "${opp.title}"'),
      backgroundColor: primary,
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
            colors: [bgGradientTop, bgGradientBot],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(children: [
          AnimatedBuilder(
            animation: _navWidth,
            builder: (_, __) => _Sidebar(
              width: _navWidth.value,
              expanded: _navExpanded,
              active: _active,
              onTap: (n) {
                final paymentComplete = (_userData?['paymentInfo']?['isComplete'] ?? false) == true;
                if (n == AppNav.onboarding && !paymentComplete) return;
                setState(() => _active = n);
              },
              onToggle: _toggleNav,
              userData: _userData,
              onLogout: _logout,
              userEmail: widget.userEmail,
              paymentComplete: (_userData?['paymentInfo']?['isComplete'] ?? false) == true,
            ),
          ),
          Expanded(child: Column(children: [
            _TopBar(active: _active, userData: _userData, docId: _docId, onMenuTap: _toggleNav),
            Expanded(child: _body()),
          ])),
        ]),
      ),
    );
  }

  Widget _body() {
    final paymentComplete = (_userData?['paymentInfo']?['isComplete'] ?? false) == true;

    switch (_active) {
      case AppNav.jobs:
        final isVerified = (_userData?['status'] ?? '') == 'approved';
        final examPassed = (_userData?['examPassed'] ?? false) == true;
        return JobsPage(
          opps: _opps,
          onSubmit: _submitInterest,
          userEmail: widget.userEmail,
          onGoToOnboarding: () => setState(() => _active = AppNav.onboarding),
          isVerified: isVerified,
          examPassed: examPassed,
          paymentComplete: paymentComplete,
        );
      case AppNav.explore:
        final examPassedExplore = (_userData?['examPassed'] ?? false) == true;
        return ExplorePage(
          opps: _opps,
          onSubmit: _submitInterest,
          examPassed: examPassedExplore,
          paymentComplete: paymentComplete,
          onGoToOnboarding: () => setState(() => _active = AppNav.onboarding),
        );
      case AppNav.payments:
        return const PaymentInfoPage();
      case AppNav.onboarding:
        return OnboardingExamPage(userEmail: widget.userEmail);
      case AppNav.profile:
        return ProfilePage(userData: _userData ?? {}, userEmail: widget.userEmail);
      case AppNav.settings:
        return SettingsPage(
          userData: _userData,
          userEmail: widget.userEmail,
          onLogout: _logout,
        );
    }
  }
}

// ===========================================================================
// SIDEBAR
// ===========================================================================

class _Sidebar extends StatelessWidget {
  final double width;
  final bool expanded;
  final AppNav active;
  final ValueChanged<AppNav> onTap;
  final VoidCallback onToggle;
  final Map<String, dynamic>? userData;
  final VoidCallback onLogout;
  final String userEmail;
  final bool paymentComplete;

  const _Sidebar({
    required this.width,
    required this.expanded,
    required this.active,
    required this.onTap,
    required this.onToggle,
    required this.userData,
    required this.onLogout,
    required this.userEmail,
    required this.paymentComplete,
  });

  static const _items = [
    (AppNav.jobs,        Icons.work_outline_rounded,              'Jobs'),
    (AppNav.explore,     Icons.explore_outlined,                  'Explore'),
    (AppNav.payments,    Icons.account_balance_wallet_outlined,   'Payments'),
    (AppNav.onboarding,  Icons.school_outlined,                   'Onboarding Exam'),
    (AppNav.profile,     Icons.person_outline_rounded,            'Profile'),
    (AppNav.settings,    Icons.settings_outlined,                 'Settings'),
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
            color: glassWhite,
            border: const Border(right: BorderSide(color: glassBorder, width: 1.5)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(2, 0))
            ],
          ),
          child: Column(children: [
            GestureDetector(
              onTap: onToggle,
              child: Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.centerLeft,
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: glassBorder, width: 1.5)),
                ),
                child: Row(children: [
                  Image.asset('assets/images/logo.png', height: 36, width: 36, fit: BoxFit.contain),
                  if (expanded) ...[
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'DATATRICKS AI',
                        style: TextStyle(color: textPrimary, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: -0.2),
                      ),
                    ),
                  ],
                ]),
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                children: [
                  ..._items.map((item) {
                    final isActive = active == item.$1;
                    final isOnboarding = item.$1 == AppNav.onboarding;
                    final isLocked = isOnboarding && !paymentComplete;
                    return _SidebarItem(
                      icon: isLocked ? Icons.lock_outline_rounded : item.$2,
                      label: item.$3,
                      isActive: isActive,
                      expanded: expanded,
                      isLocked: isLocked,
                      onTap: isLocked ? () {} : () => onTap(item.$1),
                    );
                  }),
                  const SizedBox(height: 12),
                  _OnboardingExamBannerCard(
                    expanded: expanded,
                    isActive: active == AppNav.onboarding,
                    paymentComplete: paymentComplete,
                    onTap: paymentComplete ? () => onTap(AppNav.onboarding) : () {},
                  ),
                  const SizedBox(height: 8),
                  Builder(builder: (ctx) => GestureDetector(
                    onTap: () => shareCareerLink(ctx, userEmail),
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
                          BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3)),
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

            const Divider(color: glassBorder, height: 1, thickness: 1.5),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(children: [
                Container(
                  width: 34, height: 34,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [primary, secondary], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
                if (expanded) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(firstName,
                          style: const TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis),
                      Text(userData?['email'] ?? '',
                          style: const TextStyle(color: textMuted, fontSize: 10),
                          overflow: TextOverflow.ellipsis),
                    ]),
                  ),
                  IconButton(
                    onPressed: onLogout,
                    icon: const Icon(Icons.logout_rounded, color: textMuted, size: 16),
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
  final bool isLocked;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.expanded,
    required this.onTap,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: EdgeInsets.symmetric(horizontal: expanded ? 12 : 10, vertical: 10),
      decoration: BoxDecoration(
        color: isLocked
            ? amberLight.withValues(alpha: 0.5)
            : isActive ? primaryLight.withValues(alpha: 0.8) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isLocked
            ? Border.all(color: amber.withValues(alpha: 0.35), width: 1)
            : null,
      ),
      child: Row(children: [
        Icon(icon,
            color: isLocked ? amber : isActive ? primary : textMuted,
            size: 20),
        if (expanded) ...[
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: TextStyle(
              color: isLocked ? amber : isActive ? primary : textSecondary,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              fontSize: 14,
            )),
          ),
          if (isLocked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: amber.withValues(alpha: 0.4), width: 1),
              ),
              child: const Text(
                'Locked',
                style: TextStyle(color: amber, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.3),
              ),
            ),
        ],
      ]),
    ),
  );
}

// ===========================================================================
// TOP BAR
// ===========================================================================

class _TopBar extends StatelessWidget {
  final AppNav active;
  final Map<String, dynamic>? userData;
  final String? docId;
  final VoidCallback onMenuTap;

  const _TopBar({
    required this.active,
    required this.userData,
    required this.docId,
    required this.onMenuTap,
  });

  static const _titles = {
    AppNav.jobs:        'Jobs',
    AppNav.explore:     'Explore',
    AppNav.payments:    'Payments',   
    AppNav.onboarding:  'Onboarding Exam',
    AppNav.profile:     'My Profile',
    AppNav.settings:    'Settings',
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
            color: glassWhite,
            border: Border(bottom: BorderSide(color: glassBorder, width: 1.5)),
          ),
          child: Row(children: [
            Text(_titles[active]!, style: const TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 17)),
            const Spacer(),
            GestureDetector(
              onTap: () => showStatusPopup(context, status),
              child: _StatusChip(status: status),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => showResetPasswordDialog(context, userData?['email'] ?? ''),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: primaryLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: primary.withValues(alpha: 0.25), width: 1.2),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.lock_reset_rounded, color: primary, size: 15),
                  SizedBox(width: 6),
                  Text('Reset Password', style: TextStyle(color: primary, fontWeight: FontWeight.w700, fontSize: 12)),
                ]),
              ),
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
        color: glassWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: glassBorder, width: 1.5),
      ),
      child: Icon(icon, color: textSecondary, size: 17),
    ),
  );
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    final bg    = statusBg(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(statusLabel(status), style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }
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
        gradient: LinearGradient(colors: [bgGradientTop, bgGradientBot], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primary, strokeWidth: 2.5),
            SizedBox(height: 16),
            Text('Loading...', style: TextStyle(color: textSecondary, fontSize: 14)),
          ],
        ),
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
        gradient: LinearGradient(colors: [bgGradientTop, bgGradientBot], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 54, height: 54,
              decoration: const BoxDecoration(color: redLight, shape: BoxShape.circle),
              child: const Icon(Icons.error_outline_rounded, color: red, size: 26),
            ),
            const SizedBox(height: 14),
            Text(error, style: const TextStyle(color: textSecondary, fontSize: 14)),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onBack,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(8)),
                child: const Text('Go Back', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ===========================================================================
// ONBOARDING EXAM BANNER CARD (Sidebar)
// ===========================================================================

class _OnboardingExamBannerCard extends StatelessWidget {
  final bool expanded;
  final bool isActive;
  final bool paymentComplete;
  final VoidCallback onTap;

  const _OnboardingExamBannerCard({
    required this.expanded,
    required this.isActive,
    required this.paymentComplete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!expanded) {
      return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: !paymentComplete
                ? const LinearGradient(
                    colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : isActive
                    ? const LinearGradient(
                        colors: [Color(0xFF0EA5E9), Color(0xFF6366F1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : const LinearGradient(
                        colors: [Color(0xFFE0F2FE), Color(0xFFEDE9FE)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
            boxShadow: [
              BoxShadow(
                color: (!paymentComplete
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFF6366F1))
                    .withValues(alpha: isActive ? 0.35 : 0.12),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              paymentComplete ? Icons.quiz_rounded : Icons.lock_outline_rounded,
              color: !paymentComplete
                  ? const Color(0xFFD97706)
                  : isActive ? Colors.white : const Color(0xFF6366F1),
              size: 20,
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: isActive
              ? const LinearGradient(
                  colors: [Color(0xFF0EA5E9), Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [Color(0xFFEFF6FF), Color(0xFFF5F3FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          border: Border.all(
            color: isActive
                ? Colors.transparent
                : const Color(0xFF6366F1).withValues(alpha: 0.25),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: isActive ? 0.30 : 0.08),
              blurRadius: isActive ? 16 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              right: -10,
              top: -10,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: (isActive ? Colors.white : const Color(0xFF6366F1))
                      .withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: 14,
              bottom: -6,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: (isActive ? Colors.white : const Color(0xFF0EA5E9))
                      .withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.white.withValues(alpha: 0.22)
                              : const Color(0xFF6366F1).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(
                          Icons.quiz_rounded,
                          color: isActive ? Colors.white : const Color(0xFF6366F1),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Onboarding Exam',
                              style: TextStyle(
                                color: isActive ? Colors.white : const Color(0xFF1E1B4B),
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                letterSpacing: -0.1,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Colors.white.withValues(alpha: 0.20)
                                    : const Color(0xFF10B981).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Required',
                                style: TextStyle(
                                  color: isActive ? Colors.white : const Color(0xFF059669),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete your exam to unlock full access.',
                    style: TextStyle(
                      color: isActive
                          ? Colors.white.withValues(alpha: 0.85)
                          : const Color(0xFF4338CA),
                      fontSize: 10,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: BoxDecoration(
                            color: !paymentComplete
                                ? const Color(0xFFF59E0B).withValues(alpha: 0.18)
                                : isActive
                                    ? Colors.white.withValues(alpha: 0.22)
                                    : const Color(0xFF6366F1),
                            borderRadius: BorderRadius.circular(8),
                            border: !paymentComplete
                                ? Border.all(
                                    color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                                    width: 1,
                                  )
                                : null,
                            boxShadow: (!paymentComplete || isActive)
                                ? []
                                : [
                                    BoxShadow(
                                      color: const Color(0xFF6366F1).withValues(alpha: 0.30),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                !paymentComplete
                                    ? Icons.lock_outline_rounded
                                    : Icons.arrow_forward_rounded,
                                color: !paymentComplete
                                    ? const Color(0xFFD97706)
                                    : Colors.white,
                                size: 13,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                !paymentComplete
                                    ? 'Pay Info Required'
                                    : isActive ? 'In Progress' : 'Start Exam',
                                style: TextStyle(
                                  color: !paymentComplete
                                      ? const Color(0xFFD97706)
                                      : Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}