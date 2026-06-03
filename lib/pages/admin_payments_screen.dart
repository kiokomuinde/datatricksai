import 'dart:ui';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ===========================================================================
// DATATRICKS AI - ADMIN PAYMENTS & IDENTITY VIEWER
// ===========================================================================

class AdminPaymentsScreen extends StatefulWidget {
  final String uid;
  
  const AdminPaymentsScreen({super.key, required this.uid});

  @override
  State<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends State<AdminPaymentsScreen> {

  // Opens the document in a new tab
  void _viewDoc(String? url) {
    if (url != null && url.isNotEmpty) {
      html.window.open(url, '_blank');
    }
  }

  // Safely extracts the real file extension (.png, .jpg, .pdf) from the URL
  String _extractExtension(String url) {
    try {
      String cleanUrl = url.split('?').first;
      String decoded = Uri.decodeFull(cleanUrl);
      if (decoded.contains('.')) {
        String ext = decoded.split('.').last.toLowerCase();
        // Validate it looks like a real extension (alphanumeric, max 5 chars)
        if (RegExp(r'^[a-z0-9]+$').hasMatch(ext) && ext.length <= 5) {
          return '.$ext';
        }
      }
    } catch (_) {}
    return '.pdf'; // Fallback if no extension is found
  }

  // Forces a download action on the document by fetching bytes as a local Blob
  void _downloadDoc(String? url, String baseFilename) {
    if (url != null && url.isNotEmpty) {
      String extension = _extractExtension(url);
      String fullFilename = "$baseFilename$extension";

      // Fetch the file data programmatically as a Blob to bypass cross-origin browser restrictions
      html.HttpRequest.request(url, responseType: 'blob').then((request) {
        final blob = request.response as html.Blob;
        
        // Create a local object URL from the downloaded blob (shares your website's origin)
        final String blobUrl = html.Url.createObjectUrlFromBlob(blob);
        
        // Trigger the hidden anchor click trick on the same-origin blob link
        final html.AnchorElement anchor = html.AnchorElement(href: blobUrl);
        anchor.download = fullFilename;
        
        html.document.body?.children.add(anchor); 
        anchor.click();
        anchor.remove();
        
        // Clean up memory allocations for the temporary object URL
        html.Url.revokeObjectUrl(blobUrl);
      }).catchError((error) {
        // Fallback: If network fetch fails (e.g., due to missing CORS), fall back to opening in a new tab
        html.window.open(url, '_blank');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020408),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "FINANCIAL & IDENTITY RECORD",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1.5),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          const _BackgroundCanvas(),
          
          SafeArea(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('applications').doc(widget.uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
                }
                
                if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text("Error loading applicant data.", style: TextStyle(color: Colors.redAccent)));
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                final Map<String, dynamic>? paymentInfo = data['paymentInfo'] as Map<String, dynamic>?;
                final String fullName = "${data['firstName'] ?? ''} ${data['lastName'] ?? ''}".trim();
                final String email = data['email'] ?? 'No Email';

                if (paymentInfo == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.money_off_rounded, size: 60, color: Colors.white.withValues(alpha: 0.2)),
                        const SizedBox(height: 20),
                        Text("No payment information submitted by $fullName.", style: const TextStyle(color: Colors.white54)),
                      ],
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    bool isDesktop = constraints.maxWidth > 900;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // HEADER USER CARD
                          _UserHeaderCard(fullName: fullName, email: email, data: data),
                          const SizedBox(height: 30),

                          if (isDesktop) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _IdentityCard(
                                    info: paymentInfo, 
                                    onView: _viewDoc,
                                    onDownload: _downloadDoc,
                                  )
                                ),
                                const SizedBox(width: 30),
                                Expanded(
                                  child: Column(
                                    children: [
                                      _BankingCard(info: paymentInfo),
                                      const SizedBox(height: 30),
                                      _BillingCard(info: paymentInfo),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          ] else ...[
                            _IdentityCard(
                              info: paymentInfo, 
                              onView: _viewDoc,
                              onDownload: _downloadDoc,
                            ),
                            const SizedBox(height: 30),
                            _BankingCard(info: paymentInfo),
                            const SizedBox(height: 30),
                            _BillingCard(info: paymentInfo),
                          ]
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// GLASSMORPHIC COMPONENTS
// ===========================================================================

class _UserHeaderCard extends StatelessWidget {
  final String fullName;
  final String email;
  final Map<String, dynamic> data;

  const _UserHeaderCard({required this.fullName, required this.email, required this.data});

  @override
  Widget build(BuildContext context) {
    return _GlassContainer(
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.4), width: 2),
            ),
            child: Center(
              child: Text(
                fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                style: const TextStyle(color: Color(0xFF818CF8), fontSize: 24, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fullName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(email, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_rounded, color: Color(0xFF10B981), size: 16),
                SizedBox(width: 8),
                Text("SECURE DATA RECORD", style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  final Map<String, dynamic> info;
  final Function(String?) onView;
  final Function(String?, String) onDownload;

  const _IdentityCard({
    required this.info, 
    required this.onView,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.badge_rounded, color: Color(0xFF6366F1)),
              SizedBox(width: 10),
              Text("IDENTITY VERIFICATION", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 25),
          _DataField(
            label: "Social Security Number", 
            value: info['ssn'] ?? info['ssnLast4'] ?? 'N/A'
          ),
          const SizedBox(height: 15),
          const Divider(color: Colors.white12),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(child: _DataField(label: "ID Type", value: info['idType'] ?? 'N/A')),
              Expanded(child: _DataField(label: "ID Expiry", value: info['idExpiry'] ?? 'N/A')),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _DocPreviewButton(label: "ID FRONT", url: info['idFrontUrl'], onView: onView, onDownload: onDownload)),
              const SizedBox(width: 15),
              Expanded(child: _DocPreviewButton(label: "ID BACK", url: info['idBackUrl'], onView: onView, onDownload: onDownload)),
            ],
          ),
          const SizedBox(height: 25),
          const Divider(color: Colors.white12),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(child: _DataField(label: "Driver's License State", value: info['dlState'] ?? 'N/A')),
              Expanded(child: _DataField(label: "DL Expiry", value: info['dlExpiry'] ?? 'N/A')),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _DocPreviewButton(label: "DL FRONT", url: info['dlFrontUrl'], onView: onView, onDownload: onDownload)),
              const SizedBox(width: 15),
              Expanded(child: _DocPreviewButton(label: "DL BACK", url: info['dlBackUrl'], onView: onView, onDownload: onDownload)),
            ],
          ),
        ],
      ),
    );
  }
}

class _BankingCard extends StatelessWidget {
  final Map<String, dynamic> info;

  const _BankingCard({required this.info});

  @override
  Widget build(BuildContext context) {
    return _GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance_rounded, color: Color(0xFF14B8A6)),
              SizedBox(width: 10),
              Text("BANKING INFORMATION", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 25),
          _DataField(label: "Bank Name", value: info['bankName'] ?? 'N/A'),
          const SizedBox(height: 15),
          _DataField(label: "Account Holder Name", value: info['accountHolderName'] ?? 'N/A'),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(child: _DataField(label: "Account Type", value: info['accountType'] ?? 'N/A')),
              Expanded(child: _DataField(label: "Routing Number", value: info['routingNumber'] ?? 'N/A')),
            ],
          ),
          const SizedBox(height: 15),
          _DataField(label: "Account Number", value: info['accountNumber'] ?? 'N/A'),
        ],
      ),
    );
  }
}

class _BillingCard extends StatelessWidget {
  final Map<String, dynamic> info;

  const _BillingCard({required this.info});

  @override
  Widget build(BuildContext context) {
    final dynamic rawBilling = info['billingAddress'];

    return _GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_on_rounded, color: Color(0xFFF59E0B)),
              SizedBox(width: 10),
              Text("BILLING ADDRESS", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 25),
          
          if (rawBilling == null) ...[
            const Text("No billing address provided.", style: TextStyle(color: Colors.white54))
          ] 
          else if (rawBilling is String) ...[
            _DataField(label: "Full Address", value: rawBilling),
          ] 
          else if (rawBilling is Map) ...[
            _DataField(label: "Street Address", value: rawBilling['street']?.toString() ?? 'N/A'),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(child: _DataField(label: "Apt / Suite", value: rawBilling['apt']?.toString().isEmpty == true ? 'N/A' : (rawBilling['apt']?.toString() ?? 'N/A'))),
                Expanded(child: _DataField(label: "City", value: rawBilling['city']?.toString() ?? 'N/A')),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(child: _DataField(label: "State", value: rawBilling['state']?.toString() ?? 'N/A')),
                Expanded(child: _DataField(label: "ZIP Code", value: rawBilling['zip']?.toString() ?? 'N/A')),
              ],
            ),
          ] else ...[
            const Text("Malformed billing address data.", style: TextStyle(color: Colors.redAccent))
          ]
        ],
      ),
    );
  }
}

// ── UTILITIES ─────────────────────────────────────────────────────────────

class _DataField extends StatelessWidget {
  final String label;
  final String value;

  const _DataField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white, 
              fontSize: 15, 
              fontWeight: FontWeight.w600, 
              letterSpacing: 0.5
            ),
          ),
        ),
      ],
    );
  }
}

class _DocPreviewButton extends StatelessWidget {
  final String label;
  final String? url;
  final Function(String?) onView;
  final Function(String?, String) onDownload;

  const _DocPreviewButton({
    required this.label, 
    required this.url, 
    required this.onView,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasDoc = url != null && url!.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: hasDoc ? const Color(0xFF6366F1).withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: hasDoc ? const Color(0xFF6366F1).withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main Icon & Label
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Icon(hasDoc ? Icons.image_rounded : Icons.broken_image_rounded, color: hasDoc ? const Color(0xFF818CF8) : Colors.white24, size: 24),
                const SizedBox(height: 8),
                Text(label, style: TextStyle(color: hasDoc ? const Color(0xFF818CF8) : Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ],
            ),
          ),
          
          // Action Buttons (View / Download)
          if (hasDoc) ...[
            Container(height: 1, color: const Color(0xFF6366F1).withValues(alpha: 0.2)),
            Row(
              children: [
                // VIEW BUTTON
                Expanded(
                  child: InkWell(
                    onTap: () => onView(url),
                    borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(11)),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Icon(Icons.visibility_rounded, color: Color(0xFF818CF8), size: 18),
                    ),
                  ),
                ),
                Container(width: 1, height: 38, color: const Color(0xFF6366F1).withValues(alpha: 0.2)),
                // DOWNLOAD BUTTON - Removed the hardcoded .pdf extension here
                Expanded(
                  child: InkWell(
                    onTap: () => onDownload(url, label.replaceAll(' ', '_')),
                    borderRadius: const BorderRadius.only(bottomRight: Radius.circular(11)),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Icon(Icons.download_rounded, color: Color(0xFF818CF8), size: 18),
                    ),
                  ),
                ),
              ],
            )
          ]
        ],
      ),
    );
  }
}

class _GlassContainer extends StatelessWidget {
  final Widget child;
  const _GlassContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1.5),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: -5)],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _BackgroundCanvas extends StatelessWidget {
  const _BackgroundCanvas();
  @override
  Widget build(BuildContext context) => Positioned.fill(child: CustomPaint(painter: _BgPainter()));
}

class _BgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF020408);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);
    final gridPaint = Paint()..color = Colors.white.withValues(alpha: 0.02)..strokeWidth = 1;
    for (double i = 0; i < size.width; i += 60) canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    for (double i = 0; i < size.height; i += 60) canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}