import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http; // FOR API CALLS

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
  String? _fileError;

  final List<String> _roles = [
    "Senior Machine Learning Engineer",
    "Data Annotation Specialist (Remote)",
    "Frontend Developer (Flutter)",
    "Backend Engineer (Go/Rust)",
    "Product Manager",
    "QA Automation Engineer"
  ];

  final List<String> _sources = [
    "LinkedIn", "Google Search", "Referral", "Twitter / X", "Glassdoor", "Other"
  ];

  // STATIC US STATES (Guarantees the dropdown is always clickable)
  final List<String> _states = [
    "Alabama", "Alaska", "Arizona", "Arkansas", "California", "Colorado", 
    "Connecticut", "Delaware", "Florida", "Georgia", "Hawaii", "Idaho", 
    "Illinois", "Indiana", "Iowa", "Kansas", "Kentucky", "Louisiana", 
    "Maine", "Maryland", "Massachusetts", "Michigan", "Minnesota", 
    "Mississippi", "Missouri", "Montana", "Nebraska", "Nevada", 
    "New Hampshire", "New Jersey", "New Mexico", "New York", 
    "North Carolina", "North Dakota", "Ohio", "Oklahoma", "Oregon", 
    "Pennsylvania", "Rhode Island", "South Carolina", "South Dakota", 
    "Tennessee", "Texas", "Utah", "Vermont", "Virginia", "Washington", 
    "West Virginia", "Wisconsin", "Wyoming"
  ];

  // --- API: FETCH CITIES ---
  Future<void> _fetchCities(String stateName) async {
    setState(() {
      _isLoadingCities = true;
      _cities = ["Loading..."]; // Placeholder to keep dropdown active
      _selectedCity = null; 
    });

    try {
      // Fetching cities for the specific state
      var url = Uri.parse("https://countriesnow.space/api/v0.1/countries/state/cities");
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "country": "United States",
          "state": stateName
        })
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        List<dynamic> citiesData = data['data'];
        
        if (mounted) {
          setState(() {
            _cities = citiesData.map((c) => c.toString()).toList();
            _cities.sort();
            _isLoadingCities = false;
          });
        }
      } else {
        throw Exception("Failed to load");
      }
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted) {
        setState(() {
          _cities = ["Could not load cities"];
          _isLoadingCities = false;
        });
      }
    }
  }

  // --- FILE PICKER ---
  Future<void> _pickResume() async {
    try {
      setState(() => _fileError = null); 
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'], 
      );

      if (result != null) {
        final file = result.files.first;
        if (file.size > 4 * 1024 * 1024) { 
          setState(() {
            _fileError = "File is too large (Max 4MB).";
            _resumeFile = null;
          });
          return;
        }
        setState(() => _resumeFile = file);
      }
    } catch (e) {
      setState(() => _fileError = "Failed to pick file.");
    }
  }

  void _submitApplication() {
    if (_resumeFile == null) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text("Please upload your resume."), backgroundColor: Colors.red),
       );
       return;
    }
    // Validation for dropdowns
    if (_selectedState == null || _selectedCity == null) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text("Please select your location."), backgroundColor: Colors.orange),
       );
       return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
       const SnackBar(content: Text("Application Submitted Successfully!"), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020408),
      body: Stack(
        children: [
          // 1. BACKGROUND
          const _BackgroundCanvas(),

          // 2. SCROLLABLE CONTENT
          SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            child: Center(
              child: Column(
                children: [
                  const _CareersHeader(),
                  const SizedBox(height: 40),

                  // MAIN FORM CARD
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 800),
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A).withOpacity(0.6),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 30, offset: const Offset(0, 10)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Application Form", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            const Text("Please fill out the details below. Our recruitment team reviews applications on a rolling basis.", style: TextStyle(color: Colors.white54, height: 1.5)),
                            const SizedBox(height: 40),

                            // PERSONAL INFO
                            const _SectionLabel(label: "Personal Information"),
                            const SizedBox(height: 20),
                            _ResponsiveRow(children: [
                               _NeonStrikeInput(hint: "First Name", icon: Icons.person, controller: _firstNameController),
                               _NeonStrikeInput(hint: "Last Name", icon: Icons.person_outline, controller: _lastNameController),
                            ]),
                            const SizedBox(height: 20),
                            _ResponsiveRow(children: [
                               _NeonStrikeInput(hint: "Email Address", icon: Icons.email_outlined, controller: _emailController),
                               _NeonStrikeInput(hint: "Phone Number", icon: Icons.phone_outlined, controller: _phoneController),
                            ]),

                            const SizedBox(height: 40),

                            // LOCATION (FIXED)
                            const _SectionLabel(label: "Location"),
                            const SizedBox(height: 20),
                            _ResponsiveRow(children: [
                               // STATE DROPDOWN (Static List = Always Clickable)
                               _NeonDropdown(
                                 hint: "Select State",
                                 items: _states,
                                 value: _selectedState,
                                 onChanged: (val) {
                                   if (val != null) {
                                     setState(() => _selectedState = val);
                                     _fetchCities(val); // Triggers API for cities
                                   }
                                 },
                               ),
                               // CITY DROPDOWN (Dynamic API)
                               _NeonDropdown(
                                 hint: _selectedState == null 
                                     ? "Select State First" 
                                     : (_isLoadingCities ? "Fetching Cities..." : "Select City"),
                                 items: _cities,
                                 value: _cities.contains(_selectedCity) ? _selectedCity : null,
                                 // Disable selection if loading or no state selected
                                 onChanged: (_cities.isEmpty || _cities[0] == "Loading...") 
                                    ? null 
                                    : (val) => setState(() => _selectedCity = val),
                               ),
                            ]),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(child: _NeonStrikeInput(hint: "Zip / Postal Code", icon: Icons.numbers, controller: _zipController)),
                                const SizedBox(width: 20),
                                const Expanded(child: SizedBox()), 
                              ],
                            ),

                            const SizedBox(height: 40),

                            // POSITION DETAILS
                            const _SectionLabel(label: "Position & Details"),
                            const SizedBox(height: 20),
                            _ResponsiveRow(children: [
                              _NeonDropdown(
                                hint: "Select Position", 
                                items: _roles, 
                                value: _selectedRole,
                                onChanged: (val) => setState(() => _selectedRole = val),
                              ),
                              _NeonDropdown(
                                hint: "Where did you find us?", 
                                items: _sources, 
                                value: _selectedSource,
                                onChanged: (val) => setState(() => _selectedSource = val),
                              ),
                            ]),
                            const SizedBox(height: 20),
                            _NeonStrikeInput(hint: "LinkedIn Profile URL", icon: Icons.link, controller: _linkedinController),

                            const SizedBox(height: 40),

                            // RESUME UPLOAD
                            const _SectionLabel(label: "Resume / CV"),
                            const SizedBox(height: 20),
                            _FileUploadZone(
                              onTap: _pickResume,
                              file: _resumeFile,
                              errorText: _fileError,
                            ),

                            const SizedBox(height: 50),

                            // SUBMIT
                            SizedBox(
                              width: double.infinity,
                              child: _GradientSubmitButton(
                                text: "Submit Application", 
                                onPressed: _submitApplication,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text("© 2026 DataTricks AI. All rights reserved.", style: TextStyle(color: Colors.white24)),
                ],
              ),
            ),
          ),
          
          // BACK BUTTON
          Positioned(
            top: 40, left: 20,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// COMPONENT: FILE UPLOAD ZONE
// ===========================================================================

class _FileUploadZone extends StatefulWidget {
  final VoidCallback onTap;
  final PlatformFile? file;
  final String? errorText;

  const _FileUploadZone({required this.onTap, this.file, this.errorText});

  @override
  State<_FileUploadZone> createState() => _FileUploadZoneState();
}

class _FileUploadZoneState extends State<_FileUploadZone> {
  bool isHovering = false;
  @override
  Widget build(BuildContext context) {
    bool hasFile = widget.file != null;
    bool hasError = widget.errorText != null;

    Color borderColor = hasError ? Colors.redAccent : hasFile ? const Color(0xFF10B981) : (isHovering ? const Color(0xFF6366F1) : Colors.white24);
    Color bgColor = hasError ? Colors.red.withOpacity(0.05) : hasFile ? const Color(0xFF10B981).withOpacity(0.05) : (isHovering ? const Color(0xFF6366F1).withOpacity(0.05) : Colors.transparent);

    return MouseRegion(
      onEnter: (_) => setState(() => isHovering = true),
      onExit: (_) => setState(() => isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: CustomPaint(
          painter: _DashedRectPainter(color: borderColor),
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(hasError ? Icons.error_outline : (hasFile ? Icons.check_circle_outline : Icons.cloud_upload_outlined), size: 40, color: hasError ? Colors.redAccent : (hasFile ? const Color(0xFF10B981) : (isHovering ? const Color(0xFF6366F1) : Colors.white54))),
                const SizedBox(height: 15),
                if (hasFile) ...[
                  Text(widget.file!.name, style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 5),
                  Text("${(widget.file!.size / 1024).toStringAsFixed(1)} KB", style: const TextStyle(color: Colors.white38, fontSize: 12)),
                ] else if (hasError) ...[
                  Text(widget.errorText!, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  const Text("Try again with PDF/DOCX under 4MB", style: TextStyle(color: Colors.white38, fontSize: 12)),
                ] else ...[
                  Text("Click to upload or drag and drop", style: TextStyle(color: isHovering ? Colors.white : Colors.white70, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 5),
                  const Text("PDF, DOC, DOCX (Max 4MB)", style: TextStyle(color: Colors.white38, fontSize: 12)),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// UTILS & PAINTERS
// ===========================================================================

class _DashedRectPainter extends CustomPainter {
  final Color color;
  _DashedRectPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color..strokeWidth = 2.0..style = PaintingStyle.stroke;
    final RRect rrect = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(16));
    final Path path = Path()..addRRect(rrect);
    final Path dashPath = Path();
    double distance = 0.0;
    for (final PathMetric metric in path.computeMetrics()) {
      while (distance < metric.length) {
        dashPath.addPath(metric.extractPath(distance, distance + 10), Offset.zero);
        distance += 15;
      }
    }
    canvas.drawPath(dashPath, paint);
  }
  @override
  bool shouldRepaint(_DashedRectPainter oldDelegate) => oldDelegate.color != color;
}

// DROPDOWN COMPONENT (Updated to handle empty/null)
class _NeonDropdown extends StatelessWidget {
  final String hint;
  final List<String> items;
  final String? value;
  final ValueChanged<String?>? onChanged; // Nullable for disabled state

  const _NeonDropdown({required this.hint, required this.items, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(color: const Color(0xFF020408), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10, width: 1.5)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: const TextStyle(color: Colors.white38)),
          dropdownColor: const Color(0xFF1E293B),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
          isExpanded: true,
          style: const TextStyle(color: Colors.white),
          // If items list is valid, map it. If it's empty, DropdownButton disables itself, but we handle visual hints via 'hint'.
          items: items.isEmpty ? [] : items.map((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _NeonStrikeInput extends StatefulWidget {
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  const _NeonStrikeInput({required this.hint, required this.icon, required this.controller});
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
    _animController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _focusNode.addListener(() {
      setState(() {
        _hasFocus = _focusNode.hasFocus;
        if (_hasFocus) _animController.repeat(); else { _animController.stop(); _animController.reset(); }
      });
    });
  }
  @override
  void dispose() { _focusNode.dispose(); _animController.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return CustomPaint(
          painter: _hasFocus ? _StrikeBorderPainter(progress: _animController.value) : null,
          child: Container(
            decoration: BoxDecoration(color: const Color(0xFF020408), borderRadius: BorderRadius.circular(12), border: Border.all(color: _hasFocus ? Colors.transparent : Colors.white10, width: 1.5)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              focusNode: _focusNode,
              controller: widget.controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(border: InputBorder.none, hintText: widget.hint, hintStyle: const TextStyle(color: Colors.white38), icon: Icon(widget.icon, color: _hasFocus ? const Color(0xFFEC4899) : Colors.white24)),
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
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 2.0;
    paint.shader = SweepGradient(startAngle: 0.0, endAngle: math.pi * 2, colors: const [Color(0xFF6366F1), Color(0xFFEC4899), Colors.transparent, Colors.transparent, Color(0xFF6366F1)], stops: const [0.0, 0.25, 0.5, 0.9, 1.0], transform: GradientRotation(progress * math.pi * 2)).createShader(rect);
    canvas.drawRRect(rrect, paint);
  }
  @override
  bool shouldRepaint(covariant _StrikeBorderPainter oldDelegate) => oldDelegate.progress != progress;
}

// LAYOUT UTILS
class _ResponsiveRow extends StatelessWidget {
  final List<Widget> children;
  const _ResponsiveRow({required this.children});
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth > 600) return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: children[0]), const SizedBox(width: 20), Expanded(child: children[1])]);
      else return Column(children: [children[0], const SizedBox(height: 20), children[1]]);
    });
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) => Row(children: [Container(width: 4, height: 20, color: const Color(0xFFEC4899)), const SizedBox(width: 10), Text(label.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold))]);
}

class _CareersHeader extends StatelessWidget {
  const _CareersHeader();
  @override
  Widget build(BuildContext context) => Column(children: [Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.rocket_launch, color: Color(0xFF6366F1), size: 40)), const SizedBox(height: 20), const Text("Join the Hive", style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: -1)), const SizedBox(height: 10), const Text("Help us build the intelligence layer of the future.", style: TextStyle(color: Colors.white54, fontSize: 16))]);
}

class _GradientSubmitButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  const _GradientSubmitButton({required this.text, required this.onPressed});
  @override
  Widget build(BuildContext context) => Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFEC4899)], begin: Alignment.topLeft, end: Alignment.bottomRight), boxShadow: const [BoxShadow(color: Color(0xFF6366F1), blurRadius: 20, offset: Offset(0, 5), spreadRadius: -5)]), child: ElevatedButton(onPressed: onPressed, style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: const EdgeInsets.symmetric(vertical: 22), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))));
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