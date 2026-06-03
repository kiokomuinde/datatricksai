import 'dart:ui';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

// ===========================================================================
// DATATRICKS AI — PAYMENT INFORMATION PAGE
// ===========================================================================

// ── Cloudinary config (same project as CareersPage) ─────────────────────────
const String _cloudName    = 'dgdnli7vh';
const String _uploadPreset = 'resumes_careers'; // reuse existing preset

// ── Design tokens (dark theme — matching AdminDashboard) ─────────────────────
const Color _bg          = Color(0xFF020408);
const Color _surface     = Color(0xFF0F172A);
const Color _indigo      = Color(0xFF6366F1);
const Color _indigoLight = Color(0xFF818CF8);
const Color _green       = Color(0xFF10B981);
const Color _amber       = Color(0xFFF59E0B);
const Color _red         = Color(0xFFEF4444);
const Color _textPri     = Colors.white;
const Color _textSec     = Color(0xFF94A3B8);

// ===========================================================================
// MAIN PAGE WIDGET
// ===========================================================================

class PaymentInfoPage extends StatefulWidget {
  const PaymentInfoPage({super.key});

  @override
  State<PaymentInfoPage> createState() => _PaymentInfoPageState();
}

class _PaymentInfoPageState extends State<PaymentInfoPage>
    with TickerProviderStateMixin {
  // ── Auth ────────────────────────────────────────────────────────────────────
  User? get _user => FirebaseAuth.instance.currentUser;

  // ── Loading / saving state ──────────────────────────────────────────────────
  bool _loading      = true;
  bool _saving       = false;
  bool _isComplete   = false;
  bool _isVerified   = false; // NEW: Tracks Admin Verification Status
  String _saveStatus = '';

  // ── Auto-validate: true once user has submitted once OR data already existed
  bool _autoValidate = false;

  // ── Track whether uploads are missing (shown as inline errors after load)
  bool _dlFrontMissing = false;
  bool _dlBackMissing  = false;

  // ── Section expansion ───────────────────────────────────────────────────────
  late AnimationController _expandCtrl;

  // ── Form controllers ────────────────────────────────────────────────────────

  // SSN
  final _ssnCtrl   = TextEditingController();
  bool  _ssnHidden = true;

  // DL
  final _dlStateCtrl  = TextEditingController();
  final _dlExpiryCtrl = TextEditingController();
  String? _dlFrontUrl;
  String? _dlBackUrl;
  bool _dlFrontLoading = false;
  bool _dlBackLoading  = false;

  // Banking
  final _bankNameCtrl          = TextEditingController();
  final _accountHolderCtrl     = TextEditingController();
  final _routingCtrl           = TextEditingController();
  final _accountCtrl           = TextEditingController();
  bool  _accountHidden         = true;

  // Billing address
  final _billingAddressCtrl = TextEditingController();
  final _billingCityCtrl    = TextEditingController();
  final _billingStateCtrl   = TextEditingController();
  final _billingZipCtrl     = TextEditingController();

  // ── Form key ────────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();

  // ── Active section index for stepper-style UI ───────────────────────────────
  int _activeSection = 0;

  @override
  void initState() {
    super.initState();
    _expandCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _loadExistingData();
  }

  @override
  void dispose() {
    _expandCtrl.dispose();
    _ssnCtrl.dispose();
    _dlStateCtrl.dispose(); _dlExpiryCtrl.dispose();
    _bankNameCtrl.dispose(); _accountHolderCtrl.dispose();
    _routingCtrl.dispose(); _accountCtrl.dispose();
    _billingAddressCtrl.dispose(); _billingCityCtrl.dispose();
    _billingStateCtrl.dispose(); _billingZipCtrl.dispose();
    super.dispose();
  }

  // ── Load existing Firestore data ─────────────────────────────────────────────
  Future<void> _loadExistingData() async {
    if (_user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('applications')
          .doc(_user!.uid)
          .get();

      if (!doc.exists) {
        setState(() => _loading = false);
        return;
      }

      final data    = doc.data() ?? {};
      // Extract Admin Status
      _isVerified   = data['status'] == 'approved';

      final payment = (data['paymentInfo'] as Map<String, dynamic>?) ?? {};

      if (payment.isNotEmpty) {
        // SSN — restore full formatted SSN
        if (payment['ssnFormatted'] != null) {
          _ssnCtrl.text = payment['ssnFormatted'];
        } else if (payment['ssn'] != null) {
          // fallback: reformat raw digits
          final digits = payment['ssn'].toString().replaceAll(RegExp(r'\D'), '');
          final buf = StringBuffer();
          for (int i = 0; i < digits.length && i < 9; i++) {
            if (i == 3 || i == 5) buf.write('-');
            buf.write(digits[i]);
          }
          _ssnCtrl.text = buf.toString();
        }

        // DL
        _dlStateCtrl.text  = payment['dlState']  ?? '';
        _dlExpiryCtrl.text = payment['dlExpiry'] ?? '';
        _dlFrontUrl        = payment['dlFrontUrl'];
        _dlBackUrl         = payment['dlBackUrl'];

        // Banking
        _bankNameCtrl.text      = payment['bankName']          ?? '';
        _accountHolderCtrl.text = payment['accountHolderName'] ?? '';
        _routingCtrl.text       = payment['routingNumber']     ?? '';
        if (payment['accountNumber'] != null) {
          _accountCtrl.text = payment['accountNumber'];
        }

        // Billing
        _billingAddressCtrl.text = payment['billingAddress'] ?? '';
        _billingCityCtrl.text    = payment['billingCity']    ?? '';
        _billingStateCtrl.text   = payment['billingState']   ?? '';
        _billingZipCtrl.text     = payment['billingZip']     ?? '';

        _isComplete = payment['isComplete'] == true;

        // If a record already exists, immediately show errors for any missing fields
        if (_isComplete) {
          _autoValidate    = true;
          _dlFrontMissing  = (_dlFrontUrl == null || _dlFrontUrl!.isEmpty);
          _dlBackMissing   = (_dlBackUrl  == null || _dlBackUrl!.isEmpty);
        }
      }
    } catch (e) {
      debugPrint('Load error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Upload image to Cloudinary ────────────────────────────────────────────
  Future<String?> _uploadToCloudinary(Uint8List bytes, String fileName) async {
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));

    final response = await request.send().timeout(const Duration(seconds: 60));
    if (response.statusCode == 200) {
      final body = await response.stream.bytesToString();
      final json = jsonDecode(body);
      return json['secure_url'] as String?;
    }
    return null;
  }

  // ── Pick and upload a document image ─────────────────────────────────────
  Future<String?> _pickAndUpload(String label) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.first;
    if (file.bytes == null) return null;
    _showSnack('Uploading $label…', isLoading: true);
    final url = await _uploadToCloudinary(file.bytes!, file.name);
    if (url == null) {
      _showSnack('Upload failed. Please try again.', isError: true);
      return null;
    }
    _showSnack('$label uploaded successfully!');
    return url;
  }

  // ── Save to Firestore ─────────────────────────────────────────────────────
  Future<void> _savePaymentInfo() async {
    if (!_isVerified) {
      _showSnack('You must be verified by an admin to update payments.', isError: true);
      return;
    }

    // Turn on inline validation from this point forward
    setState(() => _autoValidate = true);

    if (!(_formKey.currentState?.validate() ?? false)) {
      _showSnack('Please fill in all required fields.', isError: true);
      return;
    }

    // Validate document uploads — mark missing so tiles show error state
    setState(() {
      _dlFrontMissing = (_dlFrontUrl == null || _dlFrontUrl!.isEmpty);
      _dlBackMissing  = (_dlBackUrl  == null || _dlBackUrl!.isEmpty);
    });
    if (_dlFrontMissing || _dlBackMissing) {
      _showSnack('Please upload both sides of your Driver\'s License.', isError: true);
      return;
    }

    setState(() { _saving = true; _saveStatus = 'Saving your payment information…'; });

    try {
      final ssn = _ssnCtrl.text.replaceAll('-', '').replaceAll(' ', '');

      await FirebaseFirestore.instance
          .collection('applications')
          .doc(_user!.uid)
          .update({
        'paymentInfo': {
          // Identity
          'ssn'               : ssn,
          'ssnLast4'          : ssn.length >= 4 ? ssn.substring(ssn.length - 4) : ssn,
          'ssnFormatted'      : _ssnCtrl.text.trim(), // e.g. "123-45-6789"
          'dlFrontUrl'        : _dlFrontUrl,
          'dlBackUrl'         : _dlBackUrl,
          'dlState'           : _dlStateCtrl.text.trim(),
          'dlExpiry'          : _dlExpiryCtrl.text.trim(),
          // Banking
          'bankName'          : _bankNameCtrl.text.trim(),
          'accountHolderName' : _accountHolderCtrl.text.trim(),
          'routingNumber'     : _routingCtrl.text.trim(),
          'accountNumber'     : _accountCtrl.text.trim(),
          'accountNumberLast4': _accountCtrl.text.trim().length >= 4
              ? _accountCtrl.text.trim().substring(_accountCtrl.text.trim().length - 4)
              : _accountCtrl.text.trim(),
          // Billing
          'billingAddress'    : _billingAddressCtrl.text.trim(),
          'billingCity'       : _billingCityCtrl.text.trim(),
          'billingState'      : _billingStateCtrl.text.trim(),
          'billingZip'        : _billingZipCtrl.text.trim(),
          // Meta
          'submittedAt'       : _isComplete
              ? FieldValue.serverTimestamp()
              : FieldValue.serverTimestamp(),
          'lastUpdatedAt'     : FieldValue.serverTimestamp(),
          'isComplete'        : true,
        },
      });

      setState(() {
        _isComplete      = true;
        _dlFrontMissing  = false;
        _dlBackMissing   = false;
      });
      _showSnack('Payment information saved successfully!');
    } catch (e) {
      _showSnack('Error saving: $e', isError: true);
    } finally {
      if (mounted) setState(() { _saving = false; _saveStatus = ''; });
    }
  }

  void _showSnack(String msg, {bool isError = false, bool isLoading = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        if (isLoading)
          const SizedBox(width: 18, height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
        else
          Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600))),
      ]),
      backgroundColor: isError ? _red : (isLoading ? _indigo : _green),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(20),
      duration: Duration(seconds: isLoading ? 2 : 4),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(child: CircularProgressIndicator(color: _indigo)),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // Background grid
          const _BgGrid(),

          // Main scrollable content
          _loading
              ? const Center(child: CircularProgressIndicator(color: _indigo))
              : Column(
                  children: [
                    _buildNavbar(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 30),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 780),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Form(
                                key: _formKey,
                                autovalidateMode: _autoValidate
                                    ? AutovalidateMode.always
                                    : AutovalidateMode.disabled,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildPageHeader(),
                                    const SizedBox(height: 32),

                                    // ── Section 1: SSN ───────────────────────
                                    _buildSection(
                                      index: 0,
                                      icon: Icons.security_rounded,
                                      title: 'Social Security Number',
                                      subtitle: 'Required for tax & payroll processing',
                                      accentColor: _indigo,
                                      child: _buildSsnSection(),
                                    ),
                                    const SizedBox(height: 20),

                                    // ── Section 2: Driver's License ──────────
                                    _buildSection(
                                      index: 1,
                                      icon: Icons.credit_card_rounded,
                                      title: "Driver's License",
                                      subtitle: 'Upload front and back of your DL',
                                      accentColor: const Color(0xFF0EA5E9),
                                      child: _buildDlSection(),
                                    ),
                                    const SizedBox(height: 20),

                                    // ── Section 3: Banking ───────────────────
                                    _buildSection(
                                      index: 2,
                                      icon: Icons.account_balance_rounded,
                                      title: 'Banking Details',
                                      subtitle: 'For direct deposit of your earnings',
                                      accentColor: _green,
                                      child: _buildBankingSection(),
                                    ),
                                    const SizedBox(height: 20),

                                    // ── Section 4: Billing Address ───────────
                                    _buildSection(
                                      index: 3,
                                      icon: Icons.home_rounded,
                                      title: 'Billing Address',
                                      subtitle: 'Must match your bank records',
                                      accentColor: _amber,
                                      child: _buildBillingSection(),
                                    ),
                                    const SizedBox(height: 36),

                                    // ── Security Note ────────────────────────
                                    _buildSecurityNote(),
                                    const SizedBox(height: 32),

                                    // ── Submit Button ────────────────────────
                                    _buildSubmitButton(),
                                    const SizedBox(height: 60),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

          // Saving overlay
          if (_saving)
            Container(
              color: Colors.black.withValues(alpha: 0.6),
              child: Center(
                child: _GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const CircularProgressIndicator(color: _indigo, strokeWidth: 3),
                      const SizedBox(height: 20),
                      Text(_saveStatus,
                          style: const TextStyle(color: _textPri, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Navbar ─────────────────────────────────────────────────────────────────
  Widget _buildNavbar() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo
              Row(children: [
                const Icon(Icons.bolt_rounded, color: _indigo, size: 32),
                const SizedBox(width: 10),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DATATRICKS AI',
                        style: TextStyle(color: _textPri,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            letterSpacing: -0.5)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: _indigo,
                          borderRadius: BorderRadius.circular(4)),
                      child: const Text('PAYMENT INFO',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1)),
                    ),
                  ],
                ),
              ]),

              // Status badge + back
              Row(children: [
                // Completion badge
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isComplete
                        ? _green.withValues(alpha: 0.12)
                        : _amber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: _isComplete
                          ? _green.withValues(alpha: 0.5)
                          : _amber.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(children: [
                    Container(
                      width: 7, height: 7,
                      decoration: BoxDecoration(
                        color: _isComplete ? _green : _amber,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      _isComplete ? 'Payment Info Complete' : 'Update Payment Information',
                      style: TextStyle(
                        color: _isComplete ? _green : _amber,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ]),
                ),
                const SizedBox(width: 16),
                // Back button
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: const Row(children: [
                      Icon(Icons.arrow_back_rounded, color: Colors.white70, size: 16),
                      SizedBox(width: 8),
                      Text('Back', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  // ── Check if any saved section has missing fields ──────────────────────────
  bool _hasMissingFields() {
    return !_isSectionComplete(0) ||
           !_isSectionComplete(1) ||
           !_isSectionComplete(2) ||
           !_isSectionComplete(3) ||
           _dlFrontMissing ||
           _dlBackMissing;
  }

  // ── Page Header ────────────────────────────────────────────────────────────
  Widget _buildPageHeader() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 10),
      
      // Verification Lock Banner
      if (!_isVerified)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _red.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _red.withValues(alpha: 0.35)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.lock_outline_rounded, color: _red, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                Text('Admin Verification Required',
                    style: TextStyle(color: _red,
                        fontWeight: FontWeight.w800,
                        fontSize: 14)),
                SizedBox(height: 4),
                Text(
                  'Your account must be verified by an administrator before you can add or update your payment information. All fields are currently locked.',
                  style: TextStyle(color: Color(0xFFFCA5A5), fontSize: 12, height: 1.5),
                ),
              ]),
            ),
          ]),
        )
      else if (!_isComplete)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _amber.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _amber.withValues(alpha: 0.35)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.warning_amber_rounded, color: _amber, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                Text('Action Required: Payment Information Incomplete',
                    style: TextStyle(color: _amber,
                        fontWeight: FontWeight.w800,
                        fontSize: 14)),
                SizedBox(height: 4),
                Text(
                  'You must complete your payment details before you can receive earnings. '
                  'All fields are required and your data is stored securely.',
                  style: TextStyle(color: Color(0xFFFCD34D), fontSize: 12, height: 1.5),
                ),
              ]),
            ),
          ]),
        )
      else
        Column(children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _green.withValues(alpha: 0.35)),
            ),
            child: Row(children: [
              const Icon(Icons.verified_rounded, color: _green, size: 22),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Payment information is on file. You can update your details below at any time.',
                  style: TextStyle(color: _green, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ]),
          ),
          // Show a warning if any section is missing data after a previous save
          if (_autoValidate && _hasMissingFields()) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _red.withValues(alpha: 0.35)),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.error_outline_rounded, color: _red, size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Some fields are missing or incomplete. Please review each section below and fill in any highlighted fields to ensure your payments can be processed.',
                    style: TextStyle(color: _red, fontSize: 12, height: 1.5),
                  ),
                ),
              ]),
            ),
          ],
        ]),

      const SizedBox(height: 28),
      const Text('Payment Information',
          style: TextStyle(color: _textPri, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
      const SizedBox(height: 6),
      Text('Securely provide your identity and banking details for payroll.',
          style: TextStyle(color: _textSec, fontSize: 14)),
    ]);
  }

  // ── Generic section card ───────────────────────────────────────────────────
  Widget _buildSection({
    required int index,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accentColor,
    required Widget child,
  }) {
    final bool isActive = _activeSection == index;

    return _GlassCard(
      accentColor: isActive ? accentColor : null,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Section header (tappable)
        InkWell(
          onTap: () => setState(() => _activeSection = isActive ? -1 : index),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(color: _textPri, fontSize: 16, fontWeight: FontWeight.w800)),
                Text(subtitle, style: const TextStyle(color: _textSec, fontSize: 12)),
              ])),
              Icon(
                isActive ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                color: Colors.white38,
              ),
              const SizedBox(width: 4),
              _SectionCompleteBadge(
                index: index,
                isComplete: _isSectionComplete(index),
                showError: _autoValidate && !_isSectionComplete(index),
              ),
            ]),
          ),
        ),

        // Expandable content
        AnimatedCrossFade(
          firstChild: const SizedBox(height: 0),
          secondChild: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Divider(color: Colors.white.withValues(alpha: 0.07)),
              const SizedBox(height: 16),
              child,
            ]),
          ),
          crossFadeState: isActive ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
      ]),
    );
  }

  // ── Section completion check ────────────────────────────────────────────────
  bool _isSectionComplete(int index) {
    switch (index) {
      case 0: return _ssnCtrl.text.replaceAll(RegExp(r'\D'), '').length == 9;
      case 1: return _dlFrontUrl != null && _dlBackUrl != null && _dlStateCtrl.text.isNotEmpty && _dlExpiryCtrl.text.isNotEmpty;
      case 2: return _bankNameCtrl.text.isNotEmpty && _routingCtrl.text.length == 9 && _accountCtrl.text.length >= 4 && _accountHolderCtrl.text.isNotEmpty;
      case 3: return _billingAddressCtrl.text.isNotEmpty && _billingCityCtrl.text.isNotEmpty && _billingStateCtrl.text.isNotEmpty && _billingZipCtrl.text.length == 5;
      default: return false;
    }
  }

  // ── SSN Section ────────────────────────────────────────────────────────────
  Widget _buildSsnSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _DarkTextField(
        controller: _ssnCtrl,
        enabled: _isVerified,
        label: 'Social Security Number *',
        hint: '000-00-0000',
        obscureText: _ssnHidden,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          _SsnInputFormatter(),
        ],
        maxLength: 11,
        suffixIcon: IconButton(
          icon: Icon(_ssnHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: Colors.white38, size: 20),
          onPressed: () => setState(() => _ssnHidden = !_ssnHidden),
        ),
        validator: (v) {
          final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
          if (digits.length != 9) return 'Enter a valid 9-digit SSN';
          return null;
        },
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 12),
      _InfoNote(
        icon: Icons.lock_outline_rounded,
        text: 'Your SSN is stored securely and used only for tax form generation (W-9/1099). '
              'Access is restricted to authorized payroll personnel only.',
        color: _indigo,
      ),
    ]);
  }

  // ── Driver's License Section ───────────────────────────────────────────────
  Widget _buildDlSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: _DarkTextField(
          controller: _dlStateCtrl,
          enabled: _isVerified,
          label: 'Issuing State *',
          hint: 'e.g. California',
          validator: (v) => (v ?? '').isEmpty ? 'Required' : null,
          onChanged: (_) => setState(() {}),
        )),
        const SizedBox(width: 16),
        Expanded(child: _DarkTextField(
          controller: _dlExpiryCtrl,
          enabled: _isVerified,
          label: 'Expiry Date *',
          hint: 'MM/YYYY',
          keyboardType: TextInputType.number,
          inputFormatters: [_ExpiryInputFormatter()],
          maxLength: 7,
          validator: (v) => (v ?? '').length < 7 ? 'Enter valid MM/YYYY' : null,
          onChanged: (_) => setState(() {}),
        )),
      ]),
      const SizedBox(height: 20),
      const Text('DOCUMENT UPLOADS', style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _DocUploadTile(
            label: "DL Front Side *",
            icon: Icons.credit_card_rounded,
            enabled: _isVerified,
            url: _dlFrontUrl,
            isLoading: _dlFrontLoading,
            color: _dlFrontMissing ? _red : const Color(0xFF0EA5E9),
            isMissing: _dlFrontMissing,
            onTap: () async {
              setState(() => _dlFrontLoading = true);
              final url = await _pickAndUpload("Driver's License Front");
              if (mounted) setState(() {
                _dlFrontUrl     = url ?? _dlFrontUrl;
                _dlFrontLoading = false;
                _dlFrontMissing = (_dlFrontUrl == null || _dlFrontUrl!.isEmpty);
              });
            },
          ),
          if (_dlFrontMissing) ...[
            const SizedBox(height: 6),
            const Text('DL front side is required', style: TextStyle(color: _red, fontSize: 11)),
          ],
        ])),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _DocUploadTile(
            label: "DL Back Side *",
            icon: Icons.credit_card_outlined,
            enabled: _isVerified,
            url: _dlBackUrl,
            isLoading: _dlBackLoading,
            color: _dlBackMissing ? _red : const Color(0xFF0EA5E9),
            isMissing: _dlBackMissing,
            onTap: () async {
              setState(() => _dlBackLoading = true);
              final url = await _pickAndUpload("Driver's License Back");
              if (mounted) setState(() {
                _dlBackUrl     = url ?? _dlBackUrl;
                _dlBackLoading = false;
                _dlBackMissing = (_dlBackUrl == null || _dlBackUrl!.isEmpty);
              });
            },
          ),
          if (_dlBackMissing) ...[
            const SizedBox(height: 6),
            const Text('DL back side is required', style: TextStyle(color: _red, fontSize: 11)),
          ],
        ])),
      ]),
    ]);
  }

  // ── Banking Section ───────────────────────────────────────────────────────
  Widget _buildBankingSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _DarkTextField(
        controller: _bankNameCtrl,
        enabled: _isVerified,
        label: 'Bank Name *',
        hint: 'e.g. Chase Bank, Wells Fargo',
        validator: (v) => (v ?? '').isEmpty ? 'Required' : null,
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 16),
      _DarkTextField(
        controller: _accountHolderCtrl,
        enabled: _isVerified,
        label: 'Account Holder Full Name *',
        hint: 'As it appears on your bank account',
        validator: (v) => (v ?? '').isEmpty ? 'Required' : null,
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 16),
      _DarkTextField(
        controller: _routingCtrl,
        enabled: _isVerified,
        label: 'Routing Number (ABA) *',
        hint: '9-digit routing number',
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)],
        maxLength: 9,
        validator: (v) {
          final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
          if (d.length != 9) return 'Routing number must be exactly 9 digits';
          return null;
        },
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 16),
      _DarkTextField(
        controller: _accountCtrl,
        enabled: _isVerified,
        label: 'Bank Account Number *',
        hint: 'Your full account number',
        obscureText: _accountHidden,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(17)],
        suffixIcon: IconButton(
          icon: Icon(_accountHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: Colors.white38, size: 20),
          onPressed: () => setState(() => _accountHidden = !_accountHidden),
        ),
        validator: (v) {
          final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
          if (d.length < 4) return 'Enter a valid account number';
          return null;
        },
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 12),
      _InfoNote(
        icon: Icons.account_balance_outlined,
        text: 'Your routing and account numbers are used exclusively for direct deposit. '
              'Payments are issued bi-weekly.',
        color: _green,
      ),
    ]);
  }

  // ── Billing Address Section ────────────────────────────────────────────────
  Widget _buildBillingSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _DarkTextField(
        controller: _billingAddressCtrl,
        enabled: _isVerified,
        label: 'Street Address *',
        hint: '123 Main St, Apt 4B',
        validator: (v) => (v ?? '').isEmpty ? 'Required' : null,
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: _DarkTextField(
          controller: _billingCityCtrl,
          enabled: _isVerified,
          label: 'City *',
          hint: 'City',
          validator: (v) => (v ?? '').isEmpty ? 'Required' : null,
          onChanged: (_) => setState(() {}),
        )),
        const SizedBox(width: 16),
        Expanded(child: _DarkTextField(
          controller: _billingStateCtrl,
          enabled: _isVerified,
          label: 'State *',
          hint: 'e.g. California',
          validator: (v) => (v ?? '').isEmpty ? 'Required' : null,
          onChanged: (_) => setState(() {}),
        )),
        const SizedBox(width: 16),
        SizedBox(width: 130, child: _DarkTextField(
          controller: _billingZipCtrl,
          enabled: _isVerified,
          label: 'ZIP Code *',
          hint: '00000',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(5)],
          maxLength: 5,
          validator: (v) {
            if ((v ?? '').length != 5) return 'Invalid ZIP';
            return null;
          },
          onChanged: (_) => setState(() {}),
        )),
      ]),
    ]);
  }

  // ── Security Note ─────────────────────────────────────────────────────────
  Widget _buildSecurityNote() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.verified_user_rounded, color: _indigo, size: 20),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          Text('Your data is protected',
              style: TextStyle(color: _textPri, fontWeight: FontWeight.w700, fontSize: 13)),
          SizedBox(height: 6),
          Text(
            '• SSN and account numbers are encrypted at rest\n'
            '• Document images are stored on secure Cloudinary CDN\n'
            '• Access is restricted to authorized payroll personnel only\n'
            '• We comply with SOC 2 and applicable financial data regulations',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, height: 1.8),
          ),
        ])),
      ]),
    );
  }

  // ── Submit Button ─────────────────────────────────────────────────────────
  Widget _buildSubmitButton() {
    final bool canSubmit = _isVerified && !_saving;

    return SizedBox(
      width: double.infinity,
      child: InkWell(
        onTap: canSubmit ? _savePaymentInfo : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: canSubmit ? null : Colors.white.withValues(alpha: 0.05),
            gradient: canSubmit
                ? const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(16),
            boxShadow: canSubmit
                ? [
                    BoxShadow(
                        color: _indigo.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 6))
                  ]
                : [],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(
              _isVerified ? Icons.save_alt_rounded : Icons.lock_rounded, 
              color: canSubmit ? Colors.white : Colors.white38, 
              size: 20
            ),
            const SizedBox(width: 10),
            Text(
              _isComplete ? 'Update Payment Information' : 'Save Payment Information',
              style: TextStyle(
                color: canSubmit ? Colors.white : Colors.white38, 
                fontWeight: FontWeight.w800, 
                fontSize: 16
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ===========================================================================
// SECTION COMPLETE BADGE
// ===========================================================================

class _SectionCompleteBadge extends StatelessWidget {
  final int index;
  final bool isComplete;
  final bool showError;
  const _SectionCompleteBadge({
    required this.index,
    required this.isComplete,
    this.showError = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isComplete) {
      return Container(
        width: 24, height: 24,
        decoration: const BoxDecoration(color: _green, shape: BoxShape.circle),
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
      );
    }
    if (showError) {
      return Container(
        width: 24, height: 24,
        decoration: BoxDecoration(
          color: _red.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(color: _red.withValues(alpha: 0.6)),
        ),
        child: const Icon(Icons.priority_high_rounded, color: _red, size: 14),
      );
    }
    return Container(
      width: 24, height: 24,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Center(
        child: Text('${index + 1}',
            style: const TextStyle(color: Colors.white30, fontSize: 11, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ===========================================================================
// GLASS CARD
// ===========================================================================

class _GlassCard extends StatelessWidget {
  final Widget child;
  final Color? accentColor;
  const _GlassCard({required this.child, this.accentColor});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: _surface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: accentColor != null
                  ? accentColor!.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.07),
              width: accentColor != null ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8))
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// ===========================================================================
// DARK TEXT FIELD
// ===========================================================================

class _DarkTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool obscureText;
  final bool enabled;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const _DarkTextField({
    required this.controller,
    required this.label,
    this.hint,
    this.obscureText = false,
    this.enabled = true,
    this.keyboardType,
    this.inputFormatters,
    this.maxLength,
    this.suffixIcon,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: _textSec, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
      const SizedBox(height: 8),
      TextFormField(
        controller: controller,
        obscureText: obscureText,
        enabled: enabled,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLength: maxLength,
        validator: validator,
        onChanged: onChanged,
        style: TextStyle(color: enabled ? _textPri : Colors.white38, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 13),
          counterText: '',
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: Colors.white.withValues(alpha: enabled ? 0.04 : 0.01),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _indigo, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _red, width: 1.5),
          ),
          errorStyle: const TextStyle(color: _red, fontSize: 11),
        ),
      ),
    ]);
  }
}

// ===========================================================================
// DARK DROPDOWN
// ===========================================================================

class _DarkDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> items;
  final bool enabled;
  final String Function(T) itemLabel;
  final void Function(T?) onChanged;
  final String? Function(T?)? validator;

  const _DarkDropdown({
    required this.label,
    required this.value,
    required this.items,
    this.enabled = true,
    required this.itemLabel,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: _textSec, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
      const SizedBox(height: 8),
      DropdownButtonFormField<T>(
        value: value,
        onChanged: enabled ? onChanged : null,
        validator: validator,
        style: TextStyle(color: enabled ? _textPri : Colors.white38, fontSize: 14),
        dropdownColor: const Color(0xFF1E293B),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white.withValues(alpha: enabled ? 0.04 : 0.01),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _indigo, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _red, width: 1.5),
          ),
          errorStyle: const TextStyle(color: _red, fontSize: 11),
        ),
        items: items.map((t) => DropdownMenuItem<T>(
          value: t,
          child: Text(itemLabel(t), style: TextStyle(color: enabled ? _textPri : Colors.white38, fontSize: 13)),
        )).toList(),
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: enabled ? Colors.white38 : Colors.white12),
      ),
    ]);
  }
}

// ===========================================================================
// DOCUMENT UPLOAD TILE
// ===========================================================================

class _DocUploadTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? url;
  final bool isLoading;
  final bool enabled;
  final Color color;
  final bool isMissing;
  final VoidCallback onTap;

  const _DocUploadTile({
    required this.label,
    required this.icon,
    required this.url,
    required this.isLoading,
    this.enabled = true,
    required this.color,
    required this.onTap,
    this.isMissing = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasFile = url != null && url!.isNotEmpty;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1.0 : 0.5,
      child: InkWell(
        onTap: (!enabled || isLoading) ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: isMissing
                ? _red.withValues(alpha: 0.06)
                : hasFile
                    ? color.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isMissing
                  ? _red.withValues(alpha: 0.5)
                  : hasFile
                      ? color.withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.1),
              width: (isMissing || hasFile) ? 1.5 : 1,
            ),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (isLoading)
              SizedBox(width: 28, height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: color))
            else
              Icon(
                isMissing
                    ? Icons.error_outline_rounded
                    : hasFile
                        ? Icons.check_circle_rounded
                        : icon,
                color: isMissing ? _red : hasFile ? color : Colors.white24,
                size: 28,
              ),
            const SizedBox(height: 10),
            Text(label,
                style: TextStyle(
                  color: isMissing ? _red : hasFile ? color : Colors.white38,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(
              isMissing
                  ? 'Upload required'
                  : hasFile
                      ? 'Tap to replace'
                      : 'Tap to upload',
              style: TextStyle(
                color: isMissing
                    ? _red.withValues(alpha: 0.7)
                    : hasFile
                        ? color.withValues(alpha: 0.6)
                        : Colors.white.withValues(alpha: 0.2),
                fontSize: 10,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ===========================================================================
// INFO NOTE
// ===========================================================================

class _InfoNote extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _InfoNote({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 10),
        Expanded(child: Text(text,
            style: TextStyle(color: color.withValues(alpha: 0.85), fontSize: 12, height: 1.5))),
      ]),
    );
  }
}

// ===========================================================================
// BACKGROUND GRID  (matches AdminDashboard)
// ===========================================================================

class _BgGrid extends StatelessWidget {
  const _BgGrid();
  @override
  Widget build(BuildContext context) =>
      Positioned.fill(child: CustomPaint(painter: _BgPainter()));
}

class _BgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = _bg);
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.02)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 60)
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    for (double y = 0; y < size.height; y += 60)
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ===========================================================================
// INPUT FORMATTERS
// ===========================================================================

class _SsnInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 9; i++) {
      if (i == 3 || i == 5) buffer.write('-');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _ExpiryInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 6; i++) {
      if (i == 2) buffer.write('/');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}