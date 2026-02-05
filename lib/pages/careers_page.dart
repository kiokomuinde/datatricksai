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
  final String _uploadPreset = "resumes_careers"; // MUST BE 'UNSIGNED' & 'PUBLIC' IN CLOUDINARY
  // ------------------------------------------------

  // Form Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _zipController = TextEditingController();
  final _linkedinController = TextEditingController();
  
  // Controller for "Other" source
  final _otherSourceController = TextEditingController(); 
  
  // Controller for High School
  final _highSchoolController = TextEditingController();

  // DROPDOWN STATE
  String? _selectedRole;
  String? _selectedSource;
  
  // LOCATION STATE
  String? _selectedState;
  String? _selectedCity;
  List<String> _cities = [];
  bool _isLoadingCities = false;

  // File Upload State (Resume)
  PlatformFile? _resumeFile;
  Uint8List? _resumeBytes; 
  String? _fileError; 

  // File Upload State (Supporting Documents)
  PlatformFile? _suppFile;
  Uint8List? _suppBytes;
  String? _suppFileError;

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
    "Glassdoor",
    "Google Search",
    "Company Website",
    "Facebook",
    "Instagram",
    "Twitter / X",
    "University / Campus",
    "Job Fair",
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

  // Action to pick Supporting Document (Transcripts)
  Future<void> _pickSuppFile() async {
    try {
      setState(() => _suppFileError = null);

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'], 
        withData: true, 
      );

      if (result != null) {
        setState(() {
          _suppFile = result.files.first;
          _suppBytes = result.files.first.bytes;
          _suppFileError = null; 
        });
      }
    } catch (e) {
      debugPrint("Error picking file: $e");
    }
  }

  void _submitApplication() {
    // 1. Validation
    setState(() {
      _fileError = null;
      _suppFileError = null;
    });
    
    bool isFormValid = _formKey.currentState!.validate();
    bool isResumeValid = true;
    bool isSuppValid = true;
    
    // Validate Resume
    if (_resumeFile == null || _resumeBytes == null) {
      setState(() => _fileError = "Resume is required (PDF or DOCX)");
      isResumeValid = false;
    }

    // Validate Supporting Document (Transcripts)
    if (_suppFile == null || _suppBytes == null) {
      setState(() => _suppFileError = "High School Transcripts are required");
      isSuppValid = false;
    }

    if (!isFormValid || !isResumeValid || !isSuppValid) return;

    // 2. PREPARE DATA
    String finalSource = _selectedSource ?? "";
    if (_selectedSource == "Other") {
      finalSource = "Other: ${_otherSourceController.text.trim()}";
    }

    // 3. NAVIGATE TO WAITING PAGE
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WaitingPage(
          cloudName: _cloudName,
          uploadPreset: _uploadPreset,
          formData: {
            'firstName': _firstNameController.text.trim(),
            'lastName': _lastNameController.text.trim(),
            'email': _emailController.text.trim(),
            'phone': "+1 ${_phoneController.text.trim()}",
            'state': _selectedState,
            'city': _selectedCity,
            'zip': _zipController.text.trim(),
            'highSchool': _highSchoolController.text.trim(), 
            'role': _selectedRole,
            'linkedin': _linkedinController.text.trim(),
            'source': finalSource, 
            'resumeName': _resumeFile!.name,
            'suppDocName': _suppFile!.name, 
          },
          resumeBytes: _resumeBytes!,
          suppBytes: _suppBytes!, 
        ),
      ),
    );
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

                            // --- EDUCATION SECTION ---
                            _SectionHeader("Education"),
                            const SizedBox(height: 20),
                            _NeonInput(label: "High School Name", controller: _highSchoolController, icon: Icons.school),
                            const SizedBox(height: 40),

                            _SectionHeader("Role & Experience"),
                            const SizedBox(height: 20),
                            _NeonDropdown(label: "Position Applying For", value: _selectedRole, items: _roles, onChanged: (val) => setState(() => _selectedRole = val)),
                            const SizedBox(height: 20),
                            _NeonInput(label: "LinkedIn Profile URL (Optional)", icon: Icons.link, controller: _linkedinController, isOptional: true),
                            const SizedBox(height: 20),
                            
                            _NeonDropdown(
                              label: "How did you hear about us? (Optional)", 
                              value: _selectedSource, 
                              items: _sources, 
                              onChanged: (val) => setState(() => _selectedSource = val), 
                              isOptional: true
                            ),
                            
                            if (_selectedSource == "Other") ...[
                              const SizedBox(height: 15),
                              _NeonInput(
                                label: "Please specify", 
                                controller: _otherSourceController,
                                isOptional: false, 
                              ),
                            ],

                            const SizedBox(height: 40),

                            _SectionHeader("Resume / CV"),
                            const SizedBox(height: 15),
                            
                            // RESUME UPLOAD WIDGET
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

                            const SizedBox(height: 40),

                            // --- SUPPORTING DOCUMENTS (TRANSCRIPTS) SECTION ---
                            _SectionHeader("Supporting Documents (Transcripts)"),
                            const SizedBox(height: 15),
                            
                            InkWell(
                              onTap: _pickSuppFile,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 30),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.02),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _suppFileError != null ? Colors.redAccent : Colors.white24, 
                                    style: BorderStyle.solid,
                                    width: _suppFileError != null ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Column(children: [
                                    Icon(
                                      _suppFile == null ? Icons.folder_open : Icons.check_circle, 
                                      size: 40, 
                                      color: _suppFileError != null ? Colors.redAccent : (_suppFile == null ? Colors.white54 : const Color(0xFF6366F1))
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      _suppFile == null ? "Click to upload High School Transcripts" : _suppFile!.name,
                                      style: TextStyle(
                                        color: _suppFileError != null ? Colors.redAccent : (_suppFile == null ? Colors.white54 : Colors.white),
                                        fontWeight: _suppFile == null ? FontWeight.normal : FontWeight.bold
                                      ),
                                    ),
                                    if (_suppFileError != null) ...[
                                      const SizedBox(height: 10),
                                      Text(
                                        _suppFileError!, 
                                        style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold)
                                      )
                                    ]
                                ]),
                              ),
                            ),
                            
                            const SizedBox(height: 50),
                            SizedBox(width: double.infinity, child: _GradientButton(text: "Submit Application", onPressed: _submitApplication)),
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
// WAITING PAGE (HANDLES UPLOAD & DUPLICATE CHECK)
// ===========================================================================

class WaitingPage extends StatefulWidget {
  final Map<String, dynamic> formData;
  final Uint8List resumeBytes; 
  final Uint8List suppBytes; 
  final String cloudName;
  final String uploadPreset;

  const WaitingPage({
    super.key, 
    required this.formData, 
    required this.resumeBytes,
    required this.suppBytes,
    required this.cloudName,
    required this.uploadPreset,
  });

  @override
  State<WaitingPage> createState() => _WaitingPageState();
}

class _WaitingPageState extends State<WaitingPage> {

  @override
  void initState() {
    super.initState();
    _processApplication();
  }

  Future<void> _processApplication() async {
    try {
      // 1. CHECK FOR DUPLICATES (Use Email as Unique ID)
      final QuerySnapshot duplicateCheck = await FirebaseFirestore.instance
          .collection('applications')
          .where('email', isEqualTo: widget.formData['email'])
          .limit(1)
          .get();

      if (duplicateCheck.docs.isNotEmpty) {
        throw Exception("An application with this email already exists.");
      }

      // 2. Upload Resume to Cloudinary
      String? resumeUrl = await _uploadToCloudinary(widget.resumeBytes, widget.formData['resumeName']);
      if (resumeUrl == null) {
        throw Exception("Failed to upload resume. Please try again.");
      }

      // 3. Upload Supporting Document (Transcripts) to Cloudinary
      String? suppUrl = await _uploadToCloudinary(widget.suppBytes, widget.formData['suppDocName']);
      if (suppUrl == null) {
        throw Exception("Failed to upload supporting document. Please try again.");
      }

      // 4. Save Data to Firestore 
      await FirebaseFirestore.instance.collection('applications').add({
        'firstName': widget.formData['firstName'],
        'lastName': widget.formData['lastName'],
        'email': widget.formData['email'],
        'phone': widget.formData['phone'],
        'location': {
          'state': widget.formData['state'],
          'city': widget.formData['city'],
          'zip': widget.formData['zip'],
        },
        'highSchool': widget.formData['highSchool'], 
        'role': widget.formData['role'],
        'linkedin': widget.formData['linkedin'],
        'source': widget.formData['source'],
        'resumeUrl': resumeUrl,
        'resumeName': widget.formData['resumeName'],
        'suppDocUrl': suppUrl, 
        'suppDocName': widget.formData['suppDocName'],
        'appliedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      // 5. SUCCESS -> Navigate to Success Page
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ApplicationSuccessPage()),
        );
      }

    } catch (e) {
      // 6. ERROR -> Go back
      if (mounted) {
        String errorMessage = e.toString().replaceAll("Exception: ", "");
        debugPrint("Application Process Error: $e");
        
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF0F172A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.redAccent.withOpacity(0.2))
            ),
            title: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.redAccent),
                SizedBox(width: 10),
                Text("Submission Error", style: TextStyle(color: Colors.redAccent)),
              ],
            ),
            content: Text(errorMessage, style: const TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx); 
                  Navigator.pop(context); 
                },
                child: const Text("Go Back", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        );
      }
    }
  }

  Future<String?> _uploadToCloudinary(Uint8List fileBytes, String fileName) async {
    try {
      // IMPORTANT: Use the 'auto' endpoint so Cloudinary detects PDF/Image/Raw correctly.
      var uri = Uri.parse("https://api.cloudinary.com/v1_1/${widget.cloudName}/auto/upload");
      var request = http.MultipartRequest("POST", uri);

      request.fields['upload_preset'] = widget.uploadPreset;
      
      // Sending file bytes with filename is crucial for Cloudinary to detect extension
      request.files.add(http.MultipartFile.fromBytes(
        'file', 
        fileBytes, 
        filename: fileName
      ));

      var response = await request.send().timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        var responseData = await response.stream.toBytes();
        var responseString = String.fromCharCodes(responseData);
        var jsonMap = jsonDecode(responseString);
        
        // This 'secure_url' will now correspond to the correct resource type (image or raw)
        return jsonMap['secure_url']; 
      } else {
        debugPrint("Cloudinary Upload Failed: ${response.statusCode}");
        // Optional: Read response body for specific error message from Cloudinary
        // var responseData = await response.stream.toBytes();
        // debugPrint(String.fromCharCodes(responseData));
        return null;
      }
    } catch (e) {
      debugPrint("Cloudinary Exception: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020408),
      body: Stack(
        children: [
          const _BackgroundCanvas(),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  height: 60,
                  width: 60,
                  child: CircularProgressIndicator(color: Color(0xFF6366F1), strokeWidth: 4),
                ),
                const SizedBox(height: 30),
                const Text(
                  "Processing Application...",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Checking eligibility and uploading files.\nPlease do not close the app.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.white54),
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(40),
                constraints: const BoxConstraints(maxWidth: 500),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withOpacity(0.95),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10))
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded, size: 60, color: Color(0xFF6366F1)),
                    ),
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
                      child: ElevatedButton(
                        onPressed: () {
                           Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Return to Home", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
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

  const _NeonInput({
    required this.label, 
    this.icon, 
    required this.controller, 
    this.isEmail = false, 
    this.isPhone = false, 
    this.isZip = false, 
    this.isOptional = false
  });

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
      decoration: InputDecoration(
        labelText: label, 
        labelStyle: const TextStyle(color: Colors.white38),
        filled: true, 
        fillColor: Colors.white.withOpacity(0.05),
        prefixText: isPhone ? "+1 " : null,
        prefixStyle: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        prefixIcon: icon != null ? Icon(icon, color: Colors.white24, size: 18) : null, 
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none), 
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF6366F1))), 
        errorStyle: const TextStyle(color: Colors.redAccent, height: 1)
      ),
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
  const _GradientButton({required this.text, required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFEC4899)], begin: Alignment.topLeft, end: Alignment.bottomRight), boxShadow: const [BoxShadow(color: Color(0xFF6366F1), blurRadius: 20, offset: Offset(0, 5), spreadRadius: -5)]), child: ElevatedButton(onPressed: onPressed, style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: const EdgeInsets.symmetric(vertical: 22), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))));
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