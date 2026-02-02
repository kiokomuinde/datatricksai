import 'dart:convert';
import 'dart:ui';
// ignore: avoid_web_libraries_in_flutter
import 'dart:typed_data'; // REQUIRED: For handling file bytes across Web & Mobile
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http; // FOR CLOUDINARY UPLOAD
import 'package:cloud_firestore/cloud_firestore.dart'; // FOR DATA STORAGE

// ===========================================================================
// DATATRICKS AI - CAREERS & APPLICATION PAGE
// ===========================================================================

class CareersPage extends StatefulWidget {
  const CareersPage({super.key});

  @override
  State<CareersPage> createState() => _CareersPageState();
}

class _CareersPageState extends State<CareersPage> with TickerProviderStateMixin {
  final _scrollController = ScrollController();
  final _formKey = GlobalKey<FormState>(); 
  
  // --- CLOUDINARY CONFIGURATION (FILL THESE IN) ---
  final String _cloudName = "dgdnli7vh"; 
  final String _uploadPreset = "resumes_careers"; 
  // ------------------------------------------------

  // Form Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _zipController = TextEditingController();
  final _linkedinController = TextEditingController();
  
  // DROPDOWN STATE
  String? _selectedRole;
  String? _selectedSource;
  
  // LOCATION STATE
  String? _selectedState;
  String? _selectedCity;
  List<String> _cities = [];
  bool _isLoadingCities = false;

  // File Upload State
  PlatformFile? _resumeFile;
  Uint8List? _resumeBytes; 
  String? _fileError; 

  // Loading State
  bool _isSubmitting = false;

  final List<String> _roles = [
    "AI Data Annotator (Text)",
    "AI Data Annotator (Image/Video)",
    "Linguistics Specialist",
    "Quality Assurance Lead",
    "Python Developer (AI/ML)",
    "Project Manager"
  ];

  final List<String> _sources = [
    "LinkedIn",
    "Indeed",
    "Company Website",
    "Referral",
    "Other"
  ];

  final Map<String, List<String>> _usaStates = {
    "California": ["Los Angeles", "San Francisco", "San Diego", "San Jose"],
    "New York": ["New York City", "Buffalo", "Albany", "Rochester"],
    "Texas": ["Houston", "Austin", "Dallas", "San Antonio"],
    "Florida": ["Miami", "Orlando", "Tampa", "Jacksonville"],
    "Washington": ["Seattle", "Spokane", "Tacoma", "Bellevue"],
  };

  // ---------------------------------------------------------------------------
  // ACTIONS
  // ---------------------------------------------------------------------------

  void _goHome() {
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  void _onStateChanged(String? newState) {
    if (newState == null) return;
    setState(() {
      _selectedState = newState;
      _selectedCity = null; 
      _isLoadingCities = true;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _cities = _usaStates[newState] ?? [];
          _isLoadingCities = false;
        });
      }
    });
  }

  Future<void> _pickResume() async {
    try {
      setState(() => _fileError = null);

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        withData: true, 
      );

      if (result != null) {
        setState(() {
          _resumeFile = result.files.first;
          _resumeBytes = result.files.first.bytes;
          _fileError = null; 
        });
      }
    } catch (e) {
      debugPrint("Error picking file: $e");
    }
  }

  // --- CLOUDINARY UPLOAD LOGIC ---
  Future<String?> _uploadToCloudinary(Uint8List fileBytes, String fileName) async {
    try {
      var uri = Uri.parse("https://api.cloudinary.com/v1_1/$_cloudName/auto/upload");
      var request = http.MultipartRequest("POST", uri);

      request.fields['upload_preset'] = _uploadPreset;
      request.files.add(http.MultipartFile.fromBytes('file', fileBytes, filename: fileName));

      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await response.stream.toBytes();
        var responseString = String.fromCharCodes(responseData);
        var jsonMap = jsonDecode(responseString);
        return jsonMap['secure_url']; 
      } else {
        debugPrint("Cloudinary Error: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint("Upload Exception: $e");
      return null;
    }
  }

  Future<void> _submitApplication() async {
    setState(() => _fileError = null);
    
    // 1. Validation
    bool isFormValid = _formKey.currentState!.validate();
    bool isFileValid = true;
    if (_resumeFile == null || _resumeBytes == null) {
      setState(() => _fileError = "Resume is required (PDF or DOCX)");
      isFileValid = false;
    }

    if (!isFormValid || !isFileValid) return;

    // 2. Start Submission
    setState(() => _isSubmitting = true);

    try {
      // A. Upload to Cloudinary
      String? resumeUrl = await _uploadToCloudinary(_resumeBytes!, _resumeFile!.name);

      if (resumeUrl == null) throw Exception("Resume upload failed. Please try again.");

      // B. Save to Firestore
      await FirebaseFirestore.instance.collection('applications').add({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'location': {
          'state': _selectedState,
          'city': _selectedCity,
          'zip': _zipController.text.trim(),
        },
        'role': _selectedRole,
        'linkedin': _linkedinController.text.trim(),
        'source': _selectedSource,
        'resumeUrl': resumeUrl,
        'resumeName': _resumeFile!.name,
        'appliedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      // 3. SUCCESS -> Navigate to Success Page
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ApplicationSuccessPage()),
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020408),
      body: Stack(
        children: [
          const _BackgroundCanvas(),
          
          Column(
            children: [
              _Navbar(onHomeTap: _goHome),

              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Join the Hive", style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1)),
                            const SizedBox(height: 10),
                            const Text("Help us build the next generation of AI models.", style: TextStyle(fontSize: 18, color: Colors.white54, height: 1.5)),
                            const SizedBox(height: 40),

                            _SectionHeader("Personal Information"),
                            const SizedBox(height: 20),
                            Row(children: [
                                Expanded(child: _NeonInput(label: "First Name", controller: _firstNameController)),
                                const SizedBox(width: 20),
                                Expanded(child: _NeonInput(label: "Last Name", controller: _lastNameController)),
                            ]),
                            const SizedBox(height: 20),
                            Row(children: [
                                Expanded(child: _NeonInput(label: "Email", icon: Icons.email, controller: _emailController, isEmail: true)),
                                const SizedBox(width: 20),
                                Expanded(child: _NeonInput(label: "Phone", icon: Icons.phone, controller: _phoneController, isPhone: true)),
                            ]),
                            const SizedBox(height: 40),

                            _SectionHeader("Location"),
                            const SizedBox(height: 20),
                            Row(children: [
                                Expanded(child: _NeonDropdown(label: "State / Region", value: _selectedState, items: _usaStates.keys.toList(), onChanged: _onStateChanged)),
                                const SizedBox(width: 20),
                                Expanded(child: _isLoadingCities ? const Center(child: CircularProgressIndicator()) : _NeonDropdown(label: "City", value: _selectedCity, items: _cities, onChanged: (val) => setState(() => _selectedCity = val))),
                                const SizedBox(width: 20),
                                Expanded(child: _NeonInput(label: "Zip Code", controller: _zipController, isZip: true)),
                            ]),
                            const SizedBox(height: 40),

                            _SectionHeader("Role & Experience"),
                            const SizedBox(height: 20),
                            _NeonDropdown(label: "Position Applying For", value: _selectedRole, items: _roles, onChanged: (val) => setState(() => _selectedRole = val)),
                            const SizedBox(height: 20),
                            _NeonInput(label: "LinkedIn Profile URL (Optional)", icon: Icons.link, controller: _linkedinController, isOptional: true),
                            const SizedBox(height: 20),
                            _NeonDropdown(label: "How did you hear about us? (Optional)", value: _selectedSource, items: _sources, onChanged: (val) => setState(() => _selectedSource = val), isOptional: true),
                            const SizedBox(height: 40),

                            _SectionHeader("Resume / CV"),
                            const SizedBox(height: 15),
                            
                            // FILE UPLOAD WIDGET
                            InkWell(
                              onTap: _pickResume,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 30),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.02),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _fileError != null ? Colors.redAccent : Colors.white24, 
                                    style: BorderStyle.solid,
                                    width: _fileError != null ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Column(children: [
                                    Icon(
                                      _resumeFile == null ? Icons.cloud_upload_outlined : Icons.check_circle, 
                                      size: 40, 
                                      color: _fileError != null ? Colors.redAccent : (_resumeFile == null ? Colors.white54 : const Color(0xFF6366F1))
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      _resumeFile == null ? "Click to upload Resume (PDF, DOCX)" : _resumeFile!.name,
                                      style: TextStyle(
                                        color: _fileError != null ? Colors.redAccent : (_resumeFile == null ? Colors.white54 : Colors.white),
                                        fontWeight: _resumeFile == null ? FontWeight.normal : FontWeight.bold
                                      ),
                                    ),
                                    if (_fileError != null) ...[
                                      const SizedBox(height: 10),
                                      Text(
                                        _fileError!, 
                                        style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold)
                                      )
                                    ]
                                ]),
                              ),
                            ),
                            
                            const SizedBox(height: 50),
                            SizedBox(width: double.infinity, child: _GradientButton(text: _isSubmitting ? "Uploading..." : "Submit Application", isLoading: _isSubmitting, onPressed: _isSubmitting ? () {} : _submitApplication)),
                            const SizedBox(height: 50),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _SectionHeader(String title) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold, letterSpacing: 1.2)), const SizedBox(height: 5), Divider(color: Colors.white.withOpacity(0.1))]);
  }
}

// ===========================================================================
// APPLICATION SUCCESS PAGE
// ===========================================================================

class ApplicationSuccessPage extends StatelessWidget {
  const ApplicationSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020408),
      body: Stack(
        children: [
          const _BackgroundCanvas(),
          Center(
            child: Container(
              padding: const EdgeInsets.all(40),
              constraints: const BoxConstraints(maxWidth: 500),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withOpacity(0.8),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.rocket_launch_rounded, size: 80, color: Color(0xFF6366F1)),
                  const SizedBox(height: 30),
                  const Text(
                    "Application Sent!",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Thank you for reaching out to DataTricks AI. We have received your details and resume. Our recruitment team will review your profile and contact you if you are a good match.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.white70, height: 1.5),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: _GradientButton(
                      text: "Back to Home", 
                      onPressed: () {
                         Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                      }
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

// ---------------------------------------------------------------------------
// SUB-COMPONENTS
// ---------------------------------------------------------------------------

class _Navbar extends StatelessWidget {
  final VoidCallback onHomeTap;
  const _Navbar({required this.onHomeTap});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(height: 80, padding: const EdgeInsets.symmetric(horizontal: 40), decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))), color: Colors.black.withOpacity(0.2)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [InkWell(onTap: onHomeTap, child: Row(children: [Image.asset('assets/images/logo.png', height: 40, errorBuilder: (c,e,s) => const Icon(Icons.rocket, color: Colors.white)), const SizedBox(width: 15), const Text("DATATRICKS AI", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20))])), TextButton.icon(onPressed: onHomeTap, icon: const Icon(Icons.arrow_back, color: Colors.white54, size: 18), label: const Text("Return Home", style: TextStyle(color: Colors.white54)))]))));
  }
}

class _NeonInput extends StatelessWidget {
  final String label;
  final IconData? icon;
  final TextEditingController controller;
  final bool isEmail, isPhone, isZip, isOptional;
  const _NeonInput({required this.label, this.icon, required this.controller, this.isEmail = false, this.isPhone = false, this.isZip = false, this.isOptional = false});
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: isEmail ? TextInputType.emailAddress : (isPhone || isZip ? TextInputType.number : TextInputType.text),
      validator: (val) {
        if (isOptional && (val == null || val.trim().isEmpty)) return null;
        if (val == null || val.trim().isEmpty) return "$label is required";
        if (isEmail && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) return "Invalid email";
        if (isPhone && !RegExp(r'^\(?\d{3}\)?[\s.-]?\d{3}[\s.-]?\d{4}$').hasMatch(val)) return "Invalid US phone";
        if (isZip && !RegExp(r'^\d{5}(-\d{4})?$').hasMatch(val)) return "Invalid Zip";
        return null;
      },
      decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.white38), filled: true, fillColor: Colors.white.withOpacity(0.05), prefixIcon: icon != null ? Icon(icon, color: Colors.white24, size: 18) : null, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF6366F1))), errorStyle: const TextStyle(color: Colors.redAccent, height: 1)),
    );
  }
}

class _NeonDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final Function(String?) onChanged;
  final bool isOptional;
  const _NeonDropdown({required this.label, required this.value, required this.items, required this.onChanged, this.isOptional = false});
  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value, items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: onChanged, dropdownColor: const Color(0xFF1E293B), style: const TextStyle(color: Colors.white),
      validator: (val) { if (isOptional) return null; return val == null ? "Please select an option" : null; },
      decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.white38), filled: true, fillColor: Colors.white.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF6366F1))), errorStyle: const TextStyle(color: Colors.redAccent)),
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
    return Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFEC4899)], begin: Alignment.topLeft, end: Alignment.bottomRight), boxShadow: const [BoxShadow(color: Color(0xFF6366F1), blurRadius: 20, offset: Offset(0, 5), spreadRadius: -5)]), child: ElevatedButton(onPressed: onPressed, style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: const EdgeInsets.symmetric(vertical: 22), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))));
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
    final gridPaint = Paint()..color = Colors.white.withOpacity(0.02)..strokeWidth = 1;
    for (double i = 0; i < size.width; i += 50) canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    for (double i = 0; i < size.height; i += 50) canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}