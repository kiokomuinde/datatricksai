import 'dart:convert';
import 'dart:ui';
// ignore: avoid_web_libraries_in_flutter
import 'dart:typed_data'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http; 
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart'; // <-- ADDED FIREBASE AUTH
import 'package:share_plus/share_plus.dart'; 

// ===========================================================================
// DATATRICKS AI - CAREERS & APPLICATION PAGE
// ===========================================================================

// ===========================================================================
// EMAIL SERVICE — via Vercel backend (avoids CORS on Flutter Web)
// ===========================================================================

class EmailService {
  static const String _backendUrl = 'https://datatricksai-api.vercel.app/api/send-email';

  /// Sends a branded welcome email via the Vercel backend which calls Resend.
  static Future<void> sendPasswordEmail({
    required String toName,
    required String toEmail,
    required String role,
    required String password,
  }) async {
    final uri = Uri.parse(_backendUrl);

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'toName':       toName,
        'toEmail':      toEmail,
        'role':         role,
        'password':     password,
        'approvalNote': 'Your application is now under review by our HR team. Once verified, you will receive full access to your DataTricks AI portal. For any approval enquiries, please contact our HR team directly at hr@datatricksai.us',
      }),
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      debugPrint('Email backend error ${response.statusCode}: ${response.body}');
      throw Exception('Failed to send welcome email (${response.statusCode}).');
    }
  }
}

// ===========================================================================
// PASSWORD GENERATOR
// ===========================================================================

class PasswordGenerator {
  static const String _upper   = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
  static const String _lower   = 'abcdefghjkmnpqrstuvwxyz';
  static const String _digits  = '23456789';
  static const String _special = '!@#\$%&*';

  /// Generates a random 12-character password with at least one char from
  /// each character class, then shuffles the result.
  static String generate({int length = 12}) {
    final allChars = _upper + _lower + _digits + _special;
    final rand = DateTime.now().microsecondsSinceEpoch;

    // Seed a simple LCG so we get different results every call
    int seed = rand;
    int _next() {
      seed = (seed * 1664525 + 1013904223) & 0xFFFFFFFF;
      return seed.abs();
    }

    // Guarantee at least one of each class
    final chars = [
      _upper[_next()   % _upper.length],
      _lower[_next()   % _lower.length],
      _digits[_next()  % _digits.length],
      _special[_next() % _special.length],
    ];

    // Fill the rest randomly
    for (int i = 4; i < length; i++) {
      chars.add(allChars[_next() % allChars.length]);
    }

    // Fisher-Yates shuffle
    for (int i = chars.length - 1; i > 0; i--) {
      final j = _next() % (i + 1);
      final tmp = chars[i];
      chars[i] = chars[j];
      chars[j] = tmp;
    }

    return chars.join();
  }
}


// ===========================================================================
// CAREERS PAGE
// ===========================================================================

class CareersPage extends StatefulWidget {
  const CareersPage({super.key});

  @override
  State<CareersPage> createState() => _CareersPageState();
}

class _CareersPageState extends State<CareersPage> with TickerProviderStateMixin {
  final _scrollController = ScrollController();
  final _formKey = GlobalKey<FormState>(); 
  
  // --- CLOUDINARY CONFIGURATION ---
  final String _cloudName = "dgdnli7vh"; 
  final String _uploadPreset = "resumes_careers"; 

  final _firstNameController      = TextEditingController();
  final _lastNameController       = TextEditingController();
  final _emailController          = TextEditingController();
  final _phoneController          = TextEditingController();
  final _zipController            = TextEditingController();
  final _linkedinController       = TextEditingController();
  final _otherSourceController    = TextEditingController();
  final _highSchoolController     = TextEditingController();
  final _referralEmailController  = TextEditingController();

  String? _selectedRole;
  String? _selectedSource;
  String? _selectedCountry;
  String? _selectedState;
  String? _selectedCity;
  List<String> _states = [];
  List<String> _cities = [];
  bool _isLoadingStates = false;
  bool _isLoadingCities = false;
  DateTime? _selectedBirthDate;
  String? _birthDateError;

  PlatformFile? _resumeFile;
  Uint8List?    _resumeBytes; 
  String?       _fileError; 

  PlatformFile? _suppFile;
  Uint8List?    _suppBytes;
  String?       _suppFileError;

  final List<String> _roles = [
    "AI Chatbot Assistant",
    "AI Chatbot Conversation Designer",
    "AI Chatbot Quality Analyst",
    "AI Chatbot Trainer",
    "AI Data Annotator (Audio)",
    "AI Data Annotator (Image/Video)",
    "AI Data Annotator (Text)",
    "AI Ethics Reviewer",
    "AI Model Evaluator",
    "AI Policy Analyst",
    "AI Support Agent", 
    "AI Trust & Safety Specialist",
    "Backend Developer (Python/Node.js)",
    "Bias Mitigation Specialist",
    "Chatbot Response Evaluator",
    "Chatbot Training Data Specialist",
    "Client Onboarding Specialist",
    "Client Success Manager",
    "Cloud Infrastructure Engineer",
    "Code Review Specialist (LLM Training)",
    "Community Manager (Annotators)",
    "Community Moderator",
    "Content Moderator",
    "Conversational AI Designer",
    "Creative Writing Evaluator",
    "Customer Service Representative",
    "Customer Support Specialist",
    "Data Collection Coordinator",
    "Data Engineer",
    "Data Labeling Specialist",
    "Data Quality Analyst",
    "Data Scientist",
    "Dataset Curator",
    "Dialog Writer",
    "Dialogue Tuning Specialist",
    "Fact-Checker / Researcher",
    "Frontend Developer (Flutter)",
    "Full Stack Developer",
    "Generative AI Artist/Reviewer",
    "Help Desk Technician",
    "Human-in-the-loop (HITL) Specialist",
    "Lead Prompt Engineer",
    "Linguistics Specialist",
    "LLM English Trainer",
    "Machine Learning Engineer",
    "Math/Logic Evaluator",
    "MLOps Engineer",
    "Multilingual Data Annotator",
    "Natural Language Processing (NLP) Engineer",
    "Onboarding Specialist",
    "Ontology Engineer",
    "Operations Manager",
    "Project Manager",
    "Prompt Engineer",
    "Python Developer (AI/ML)",
    "Quality Assurance Lead",
    "Quality Control Auditor",
    "Recruitment Coordinator",
    "Red Teamer (AI Safety)",
    "Reinforcement Learning Feedback Specialist",
    "Semantic Annotator",
    "Senior AI Researcher",
    "Sentiment Analysis Evaluator",
    "Subject Matter Expert - Coding",
    "Subject Matter Expert - Finance",
    "Subject Matter Expert - Law",
    "Subject Matter Expert - Medicine",
    "Subject Matter Expert - STEM",
    "Technical Support Engineer",
    "Technical Writer (AI/ML)",
    "Training Material Developer",
    "Transcription Specialist",
    "Translation Specialist (AI Training)",
    "User Experience (UX) Support"
  ];

  final List<String> _sources = [
    "LinkedIn", "Indeed", "Glassdoor", "Google Search", "Company Website",
    "Facebook", "Instagram", "Twitter / X", "University / Campus",
    "Job Fair", "Referral", "Other",
  ];

  // Country -> State/Province/Region -> Cities
  final Map<String, Map<String, List<String>>> _countryData = {
    "United States": {
      "Alabama": ["Birmingham", "Montgomery", "Huntsville", "Mobile"],
      "Alaska": ["Anchorage", "Fairbanks", "Juneau", "Sitka"],
      "Arizona": ["Phoenix", "Tucson", "Mesa", "Chandler"],
      "Arkansas": ["Little Rock", "Fort Smith", "Fayetteville", "Springdale"],
      "California": ["Los Angeles", "San Francisco", "San Diego", "Sacramento", "San Jose"],
      "Colorado": ["Denver", "Colorado Springs", "Aurora", "Fort Collins"],
      "Connecticut": ["Bridgeport", "New Haven", "Stamford", "Hartford"],
      "Delaware": ["Wilmington", "Dover", "Newark", "Middletown"],
      "Florida": ["Miami", "Orlando", "Tampa", "Jacksonville"],
      "Georgia": ["Atlanta", "Augusta", "Columbus", "Savannah"],
      "Hawaii": ["Honolulu", "Pearl City", "Hilo", "Kailua"],
      "Idaho": ["Boise", "Meridian", "Nampa", "Idaho Falls"],
      "Illinois": ["Chicago", "Aurora", "Joliet", "Naperville"],
      "Indiana": ["Indianapolis", "Fort Wayne", "Evansville", "South Bend"],
      "Iowa": ["Des Moines", "Cedar Rapids", "Davenport", "Sioux City"],
      "Kansas": ["Wichita", "Overland Park", "Kansas City", "Olathe"],
      "Kentucky": ["Louisville", "Lexington", "Bowling Green", "Owensboro"],
      "Louisiana": ["New Orleans", "Baton Rouge", "Shreveport", "Lafayette"],
      "Maine": ["Portland", "Lewiston", "Bangor", "South Portland"],
      "Maryland": ["Baltimore", "Columbia", "Germantown", "Silver Spring"],
      "Massachusetts": ["Boston", "Worcester", "Springfield", "Cambridge"],
      "Michigan": ["Detroit", "Grand Rapids", "Warren", "Sterling Heights"],
      "Minnesota": ["Minneapolis", "St. Paul", "Rochester", "Duluth"],
      "Mississippi": ["Jackson", "Gulfport", "Southaven", "Hattiesburg"],
      "Missouri": ["Kansas City", "St. Louis", "Springfield", "Columbia"],
      "Montana": ["Billings", "Missoula", "Great Falls", "Bozeman"],
      "Nebraska": ["Omaha", "Lincoln", "Bellevue", "Grand Island"],
      "Nevada": ["Las Vegas", "Henderson", "Reno", "North Las Vegas"],
      "New Hampshire": ["Manchester", "Nashua", "Concord", "Derry"],
      "New Jersey": ["Newark", "Jersey City", "Paterson", "Elizabeth"],
      "New Mexico": ["Albuquerque", "Las Cruces", "Rio Rancho", "Santa Fe"],
      "New York": ["New York City", "Buffalo", "Rochester", "Yonkers", "Syracuse"],
      "North Carolina": ["Charlotte", "Raleigh", "Greensboro", "Durham"],
      "North Dakota": ["Fargo", "Bismarck", "Grand Forks", "Minot"],
      "Ohio": ["Columbus", "Cleveland", "Cincinnati", "Toledo"],
      "Oklahoma": ["Oklahoma City", "Tulsa", "Norman", "Broken Arrow"],
      "Oregon": ["Portland", "Salem", "Eugene", "Gresham"],
      "Pennsylvania": ["Philadelphia", "Pittsburgh", "Allentown", "Erie"],
      "Rhode Island": ["Providence", "Warwick", "Cranston", "Pawtucket"],
      "South Carolina": ["Charleston", "Columbia", "North Charleston", "Mount Pleasant"],
      "South Dakota": ["Sioux Falls", "Rapid City", "Aberdeen", "Brookings"],
      "Tennessee": ["Nashville", "Memphis", "Knoxville", "Chattanooga"],
      "Texas": ["Houston", "San Antonio", "Dallas", "Austin", "Fort Worth"],
      "Utah": ["Salt Lake City", "West Valley City", "Provo", "West Jordan"],
      "Vermont": ["Burlington", "South Burlington", "Rutland", "Barre"],
      "Virginia": ["Virginia Beach", "Norfolk", "Chesapeake", "Richmond"],
      "Washington": ["Seattle", "Spokane", "Tacoma", "Vancouver", "Bellevue"],
      "West Virginia": ["Charleston", "Huntington", "Morgantown", "Parkersburg"],
      "Wisconsin": ["Milwaukee", "Madison", "Green Bay", "Kenosha"],
      "Wyoming": ["Cheyenne", "Casper", "Laramie", "Gillette"],
    },
    "India": {
      "Andhra Pradesh": ["Visakhapatnam", "Vijayawada", "Guntur", "Tirupati"],
      "Arunachal Pradesh": ["Itanagar", "Naharlagun", "Pasighat", "Tawang"],
      "Assam": ["Guwahati", "Silchar", "Dibrugarh", "Jorhat"],
      "Bihar": ["Patna", "Gaya", "Bhagalpur", "Muzaffarpur"],
      "Chhattisgarh": ["Raipur", "Bhilai", "Bilaspur", "Durg"],
      "Goa": ["Panaji", "Margao", "Vasco da Gama", "Mapusa"],
      "Gujarat": ["Ahmedabad", "Surat", "Vadodara", "Rajkot"],
      "Haryana": ["Gurugram", "Faridabad", "Panipat", "Ambala"],
      "Himachal Pradesh": ["Shimla", "Manali", "Dharamshala", "Solan"],
      "Jharkhand": ["Ranchi", "Jamshedpur", "Dhanbad", "Bokaro"],
      "Karnataka": ["Bengaluru", "Mysuru", "Mangaluru", "Hubballi"],
      "Kerala": ["Kochi", "Thiruvananthapuram", "Kozhikode", "Kollam"],
      "Madhya Pradesh": ["Indore", "Bhopal", "Jabalpur", "Gwalior"],
      "Maharashtra": ["Mumbai", "Pune", "Nagpur", "Nashik"],
      "Manipur": ["Imphal", "Thoubal", "Bishnupur", "Churachandpur"],
      "Meghalaya": ["Shillong", "Tura", "Jowai", "Nongstoin"],
      "Mizoram": ["Aizawl", "Lunglei", "Champhai", "Serchhip"],
      "Nagaland": ["Kohima", "Dimapur", "Mokokchung", "Tuensang"],
      "Odisha": ["Bhubaneswar", "Cuttack", "Rourkela", "Berhampur"],
      "Punjab": ["Ludhiana", "Amritsar", "Jalandhar", "Patiala"],
      "Rajasthan": ["Jaipur", "Jodhpur", "Udaipur", "Kota"],
      "Sikkim": ["Gangtok", "Namchi", "Gyalshing", "Mangan"],
      "Tamil Nadu": ["Chennai", "Coimbatore", "Madurai", "Tiruchirappalli"],
      "Telangana": ["Hyderabad", "Warangal", "Nizamabad", "Karimnagar"],
      "Tripura": ["Agartala", "Udaipur", "Dharmanagar", "Kailashahar"],
      "Uttar Pradesh": ["Lucknow", "Kanpur", "Noida", "Varanasi", "Agra"],
      "Uttarakhand": ["Dehradun", "Haridwar", "Nainital", "Rishikesh"],
      "West Bengal": ["Kolkata", "Howrah", "Durgapur", "Siliguri"],
      "Andaman and Nicobar Islands": ["Port Blair"],
      "Chandigarh": ["Chandigarh"],
      "Dadra and Nagar Haveli and Daman and Diu": ["Silvassa", "Daman"],
      "Delhi": ["New Delhi", "Dwarka", "Rohini", "Karol Bagh"],
      "Jammu and Kashmir": ["Srinagar", "Jammu", "Anantnag"],
      "Ladakh": ["Leh", "Kargil"],
      "Lakshadweep": ["Kavaratti"],
      "Puducherry": ["Puducherry", "Karaikal"],
    },
    "Canada": {
      "Alberta": ["Calgary", "Edmonton", "Red Deer", "Lethbridge"],
      "British Columbia": ["Vancouver", "Victoria", "Surrey", "Kelowna"],
      "Manitoba": ["Winnipeg", "Brandon", "Steinbach", "Winkler"],
      "New Brunswick": ["Moncton", "Saint John", "Fredericton", "Dieppe"],
      "Newfoundland and Labrador": ["St. John's", "Mount Pearl", "Corner Brook"],
      "Northwest Territories": ["Yellowknife", "Hay River", "Inuvik"],
      "Nova Scotia": ["Halifax", "Dartmouth", "Sydney", "Truro"],
      "Nunavut": ["Iqaluit", "Rankin Inlet", "Arviat"],
      "Ontario": ["Toronto", "Ottawa", "Mississauga", "Hamilton", "London"],
      "Prince Edward Island": ["Charlottetown", "Summerside"],
      "Quebec": ["Montreal", "Quebec City", "Laval", "Gatineau"],
      "Saskatchewan": ["Saskatoon", "Regina", "Prince Albert", "Moose Jaw"],
      "Yukon": ["Whitehorse", "Dawson City"],
    },
    "United Kingdom": {
      "England": ["London", "Manchester", "Birmingham", "Liverpool", "Leeds"],
      "Scotland": ["Edinburgh", "Glasgow", "Aberdeen", "Dundee"],
      "Wales": ["Cardiff", "Swansea", "Newport", "Wrexham"],
      "Northern Ireland": ["Belfast", "Derry", "Lisburn", "Newry"],
    },
    "Philippines": {
      "National Capital Region (NCR)": ["Manila", "Quezon City", "Makati", "Pasig"],
      "Cordillera Administrative Region (CAR)": ["Baguio", "Tabuk", "La Trinidad"],
      "Ilocos Region (Region I)": ["Laoag", "Vigan", "San Fernando"],
      "Cagayan Valley (Region II)": ["Tuguegarao", "Ilagan", "Cauayan"],
      "Central Luzon (Region III)": ["Angeles", "San Fernando", "Malolos", "Olongapo"],
      "Calabarzon (Region IV-A)": ["Antipolo", "Batangas City", "Lucena", "Calamba"],
      "Mimaropa (Region IV-B)": ["Puerto Princesa", "Calapan", "Odiongan"],
      "Bicol Region (Region V)": ["Legazpi", "Naga", "Sorsogon"],
      "Western Visayas (Region VI)": ["Iloilo City", "Bacolod", "Roxas"],
      "Central Visayas (Region VII)": ["Cebu City", "Mandaue", "Tagbilaran"],
      "Eastern Visayas (Region VIII)": ["Tacloban", "Ormoc", "Calbayog"],
      "Zamboanga Peninsula (Region IX)": ["Zamboanga City", "Pagadian", "Dipolog"],
      "Northern Mindanao (Region X)": ["Cagayan de Oro", "Iligan", "Malaybalay"],
      "Davao Region (Region XI)": ["Davao City", "Tagum", "Panabo"],
      "Soccsksargen (Region XII)": ["Koronadal", "General Santos", "Kidapawan"],
      "Caraga (Region XIII)": ["Butuan", "Surigao", "Bislig"],
      "Bangsamoro (BARMM)": ["Cotabato City", "Marawi", "Jolo"],
    },
  };

  String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  void _goHome() {
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  void _onCountryChanged(String? newCountry) {
    if (newCountry == null) return;
    setState(() {
      _selectedCountry = newCountry;
      _selectedState = null;
      _selectedCity = null;
      _cities = [];
      _isLoadingStates = true;
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _states = _countryData[newCountry]?.keys.toList() ?? [];
          _isLoadingStates = false;
        });
      }
    });
  }

  void _onStateChanged(String? newState) {
    if (newState == null || _selectedCountry == null) return;
    setState(() {
      _selectedState = newState;
      _selectedCity = null; 
      _isLoadingCities = true;
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _cities = _countryData[_selectedCountry]?[newState] ?? [];
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

  Future<void> _pickBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1940, 1, 1),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 16)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF6366F1),
              onPrimary: Colors.white,
              surface: Color(0xFF0F172A),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF0F172A),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedBirthDate = picked;
        _birthDateError = null;
      });
    }
  }

  void _submitApplication() {
    setState(() {
      _fileError = null;
      _suppFileError = null;
    });
    
    bool isFormValid  = _formKey.currentState!.validate();
    bool isResumeValid = true;
    bool isSuppValid   = true;
    
    if (_resumeFile == null || _resumeBytes == null) {
      setState(() => _fileError = "Resume is required (PDF or DOCX)");
      isResumeValid = false;
    }
    if (_suppFile == null || _suppBytes == null) {
      setState(() => _suppFileError = "High School Transcripts are required");
      isSuppValid = false;
    }
    bool isBirthDateValid = true;
    if (_selectedBirthDate == null) {
      setState(() => _birthDateError = "Date of Birth is required");
      isBirthDateValid = false;
    }
    if (!isFormValid || !isResumeValid || !isSuppValid || !isBirthDateValid) return;

    String finalSource = _selectedSource ?? "";
    if (_selectedSource == "Other") {
      finalSource = "Other: ${_otherSourceController.text.trim()}";
    }
    final String referralEmail = _selectedSource == "Referral"
        ? _referralEmailController.text.trim()
        : "";

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WaitingPage(
          cloudName:    _cloudName,
          uploadPreset: _uploadPreset,
          formData: {
            'firstName':     _firstNameController.text.trim(),
            'lastName':      _lastNameController.text.trim(),
            'email':         _emailController.text.trim(),
            'phone':         "+1 ${_phoneController.text.trim()}",
            'country':       _selectedCountry,
            'state':         _selectedState,
            'city':          _selectedCity,
            'zip':           _zipController.text.trim(),
            'highSchool':    _highSchoolController.text.trim(),
            'role':          _selectedRole,
            'linkedin':      _linkedinController.text.trim(),
            'source':        finalSource,
            'referralEmail': referralEmail,
            'resumeName':    _resumeFile!.name,
            'suppDocName':   _suppFile!.name,
            'birthDate':     _selectedBirthDate != null
                ? _formatDate(_selectedBirthDate!)
                : '',
          },
          resumeBytes: _resumeBytes!,
          suppBytes:   _suppBytes!,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _zipController.dispose();
    _linkedinController.dispose();
    _otherSourceController.dispose();
    _highSchoolController.dispose();
    _referralEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile  = screenWidth < 600;
    final isTablet  = screenWidth >= 600 && screenWidth < 1000;

    final double maxContentWidth = screenWidth >= 1200
        ? 960
        : screenWidth >= 900
            ? 800
            : double.infinity;
    final double horizontalPadding = isMobile ? 16 : (isTablet ? 24 : 40);
    final double verticalPadding   = isMobile ? 24 : 40;
    final double titleFontSize     = isMobile ? 30 : (isTablet ? 36 : 42);
    final double subtitleFontSize  = isMobile ? 15 : 18;

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
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
                  child: Center(
                    child: Container(
                      constraints: BoxConstraints(maxWidth: maxContentWidth),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Join the Hive",
                              style: TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "Help us build the next generation of AI models.",
                              style: TextStyle(fontSize: subtitleFontSize, color: Colors.white54, height: 1.5),
                            ),
                            const SizedBox(height: 40),

                            _SectionHeader("Personal Information"),
                            const SizedBox(height: 20),
                            _ResponsiveFieldRow(children: [
                              _NeonInput(label: "First Name", controller: _firstNameController),
                              _NeonInput(label: "Last Name", controller: _lastNameController),
                            ]),
                            const SizedBox(height: 20),
                            _ResponsiveFieldRow(children: [
                              _NeonInput(label: "Email", icon: Icons.email, controller: _emailController, isEmail: true),
                              _NeonInput(label: "Phone", icon: Icons.phone, controller: _phoneController, isPhone: true),
                            ]),
                            const SizedBox(height: 20),
                            // Date of Birth picker
                            FormField<DateTime>(
                              validator: (_) => _birthDateError,
                              builder: (state) => InkWell(
                                onTap: _pickBirthDate,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _birthDateError != null ? Colors.redAccent : Colors.transparent,
                                      width: _birthDateError != null ? 1.5 : 0,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.cake_outlined, color: Color(0xFF6366F1), size: 20),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _selectedBirthDate == null
                                              ? 'Date of Birth'
                                              : _formatDate(_selectedBirthDate!),
                                          style: TextStyle(
                                            color: _selectedBirthDate == null
                                                ? (_birthDateError != null ? Colors.redAccent : Colors.white38)
                                                : Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      const Icon(Icons.calendar_today, color: Colors.white38, size: 18),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (_birthDateError != null) ...[
                              const SizedBox(height: 6),
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Text(_birthDateError!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                              ),
                            ],
                            const SizedBox(height: 40),

                            _SectionHeader("Location"),
                            const SizedBox(height: 20),
                            _ResponsiveFieldRow(
                              breakpoint: 750,
                              children: [
                                _NeonDropdown(label: "Country", value: _selectedCountry, items: _countryData.keys.toList(), onChanged: _onCountryChanged),
                                _isLoadingStates
                                    ? const SizedBox(height: 58, child: Center(child: SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))))
                                    : _NeonDropdown(label: "State / Region", value: _selectedState, items: _states, onChanged: _onStateChanged),
                                _isLoadingCities
                                    ? const SizedBox(height: 58, child: Center(child: SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))))
                                    : _NeonDropdown(label: "City", value: _selectedCity, items: _cities, onChanged: (val) => setState(() => _selectedCity = val)),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _NeonInput(label: "Zip / Postal Code", controller: _zipController, isZip: true),
                            const SizedBox(height: 40),

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
                              isOptional: true,
                            ),
                            if (_selectedSource == "Other") ...[
                              const SizedBox(height: 15),
                              _NeonInput(label: "Please specify", controller: _otherSourceController, isOptional: false),
                            ],
                            // ── Referral email field — visible only when "Referral" is selected ──
                            AnimatedSize(
                              duration: const Duration(milliseconds: 280),
                              curve: Curves.easeInOut,
                              child: _selectedSource == "Referral"
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 15),
                                        TextFormField(
                                          controller: _referralEmailController,
                                          style: const TextStyle(color: Colors.white),
                                          keyboardType: TextInputType.emailAddress,
                                          validator: (val) {
                                            if (_selectedSource != "Referral") return null;
                                            if (val == null || val.trim().isEmpty) {
                                              return "Referral email is required";
                                            }
                                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val.trim())) {
                                              return "Please enter a valid email address";
                                            }
                                            return null;
                                          },
                                          decoration: InputDecoration(
                                            labelText: "Referrer's DataTricks Account Email",
                                            labelStyle: const TextStyle(color: Colors.white38),
                                            hintText: "e.g. colleague@example.com",
                                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.18), fontSize: 13),
                                            filled: true,
                                            fillColor: const Color(0xFF6366F1).withOpacity(0.07),
                                            prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF6366F1), size: 18),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: BorderSide.none,
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: BorderSide(color: const Color(0xFF6366F1).withOpacity(0.35), width: 1),
                                            ),
                                            errorStyle: const TextStyle(color: Colors.redAccent, height: 1),
                                            suffixIcon: Container(
                                              margin: const EdgeInsets.all(6),
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF6366F1).withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Text(
                                                "Required",
                                                style: TextStyle(color: Color(0xFF6366F1), fontSize: 10, fontWeight: FontWeight.w700),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(Icons.info_outline_rounded, color: Color(0xFF6366F1), size: 13),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                "Enter the DataTricks account email of the person who referred you. This is required to credit their referral reward.",
                                                style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 11, height: 1.5),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    )
                                  : const SizedBox.shrink(),
                            ),
                            const SizedBox(height: 40),

                            _SectionHeader("Resume / CV"),
                            const SizedBox(height: 15),
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
                                    width: _fileError != null ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Column(children: [
                                  Icon(
                                    _resumeFile == null ? Icons.cloud_upload_outlined : Icons.check_circle, 
                                    size: 40, 
                                    color: _fileError != null ? Colors.redAccent : (_resumeFile == null ? Colors.white54 : const Color(0xFF6366F1)),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    _resumeFile == null ? "Click to upload Resume (PDF, DOCX)" : _resumeFile!.name,
                                    style: TextStyle(
                                      color: _fileError != null ? Colors.redAccent : (_resumeFile == null ? Colors.white54 : Colors.white),
                                      fontWeight: _resumeFile == null ? FontWeight.normal : FontWeight.bold,
                                    ),
                                  ),
                                  if (_fileError != null) ...[
                                    const SizedBox(height: 10),
                                    Text(_fileError!, style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                                  ]
                                ]),
                              ),
                            ),
                            const SizedBox(height: 40),

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
                                    width: _suppFileError != null ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Column(children: [
                                  Icon(
                                    _suppFile == null ? Icons.folder_open : Icons.check_circle, 
                                    size: 40, 
                                    color: _suppFileError != null ? Colors.redAccent : (_suppFile == null ? Colors.white54 : const Color(0xFF6366F1)),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    _suppFile == null ? "Click to upload High School Transcripts" : _suppFile!.name,
                                    style: TextStyle(
                                      color: _suppFileError != null ? Colors.redAccent : (_suppFile == null ? Colors.white54 : Colors.white),
                                      fontWeight: _suppFile == null ? FontWeight.normal : FontWeight.bold,
                                    ),
                                  ),
                                  if (_suppFileError != null) ...[
                                    const SizedBox(height: 10),
                                    Text(_suppFileError!, style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                                  ]
                                ]),
                              ),
                            ),

                            const SizedBox(height: 50),
                            SizedBox(
                              width: double.infinity,
                              child: _GradientButton(text: "Submit Application", onPressed: _submitApplication),
                            ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        const SizedBox(height: 5),
        Divider(color: Colors.white.withOpacity(0.1)),
      ],
    );
  }
}

// ===========================================================================
// WAITING PAGE (HANDLES UPLOAD, DUPLICATE CHECK & EMAIL)
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

  // Tracks the current step shown to the user
  String _statusMessage = "Checking eligibility...";

  @override
  void initState() {
    super.initState();
    _processApplication();
  }

  void _setStatus(String message) {
    if (mounted) setState(() => _statusMessage = message);
  }

  Future<void> _processApplication() async {
    try {
      // ── STEP 1: Duplicate email check ────────────────────────────────────
      _setStatus("Checking eligibility...");
      final QuerySnapshot duplicateCheck = await FirebaseFirestore.instance
          .collection('applications')
          .where('email', isEqualTo: widget.formData['email'])
          .limit(1)
          .get();

      if (duplicateCheck.docs.isNotEmpty) {
        throw Exception("An application with this email already exists.");
      }

      // ── STEP 2: Upload resume ─────────────────────────────────────────────
      _setStatus("Uploading resume...");
      String? resumeUrl = await _uploadToCloudinary(widget.resumeBytes, widget.formData['resumeName']);
      if (resumeUrl == null) throw Exception("Failed to upload resume. Please try again.");

      // ── STEP 3: Upload transcripts ────────────────────────────────────────
      _setStatus("Uploading transcripts...");
      String? suppUrl = await _uploadToCloudinary(widget.suppBytes, widget.formData['suppDocName']);
      if (suppUrl == null) throw Exception("Failed to upload supporting document. Please try again.");

      // ── STEP 4: Generate a secure random password & Create Auth Account ──
      _setStatus("Creating your account securely...");
      final String generatedPassword = PasswordGenerator.generate();

      UserCredential? userCredential;
      try {
        // Create the user account directly in Firebase Authentication
        userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: widget.formData['email'],
          password: generatedPassword,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          throw Exception("An account or application with this email already exists.");
        }
        throw Exception("Account creation failed: ${e.message}");
      }

      // ── STEP 5: Save to Firestore (Secured) ───────────────────────────────
      _setStatus("Saving your application...");
      
      // Best Practice: Save the application document using the new user's Auth UID.
      // Notice: 'tempPassword' has been completely removed for security!
      await FirebaseFirestore.instance
          .collection('applications')
          .doc(userCredential.user!.uid) 
          .set({
        'uid':         userCredential.user!.uid, 
        'firstName':   widget.formData['firstName'],
        'lastName':    widget.formData['lastName'],
        'email':       widget.formData['email'],
        'phone':       widget.formData['phone'],
        'location': {
          'country': widget.formData['country'],
          'state':   widget.formData['state'],
          'city':    widget.formData['city'],
          'zip':     widget.formData['zip'],
        },
        'highSchool':  widget.formData['highSchool'], 
        'role':        widget.formData['role'],
        'linkedin':    widget.formData['linkedin'],
        'source':      widget.formData['source'],
        'resumeUrl':   resumeUrl,
        'resumeName':  widget.formData['resumeName'],
        'suppDocUrl':  suppUrl, 
        'suppDocName': widget.formData['suppDocName'],
        'birthDate':   widget.formData['birthDate'],
        'appliedAt':   FieldValue.serverTimestamp(),
        'status':      'pending',
      });

      // ── STEP 6: Send welcome email with password via EmailJS ──────────────
      _setStatus("Sending your welcome email...");
      try {
        await EmailService.sendPasswordEmail(
          toName:   "${widget.formData['firstName']} ${widget.formData['lastName']}",
          toEmail:  widget.formData['email'],
          role:     widget.formData['role'] ?? 'AI Contributor',
          password: generatedPassword,
        );
      } catch (emailError) {
        // Email failure is non-fatal — application is already saved.
        // Log it and continue to the success screen.
        debugPrint("⚠️ Email send failed (non-fatal): $emailError");
      }

      // ── STEP 7: Navigate to success screen ───────────────────────────────
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ApplicationSuccessPage()),
        );
      }

    } catch (e) {
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
              side: BorderSide(color: Colors.redAccent.withOpacity(0.2)),
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
              ),
            ],
          ),
        );
      }
    }
  }

  Future<String?> _uploadToCloudinary(Uint8List fileBytes, String fileName) async {
    try {
      var uri = Uri.parse("https://api.cloudinary.com/v1_1/${widget.cloudName}/auto/upload");
      var request = http.MultipartRequest("POST", uri);
      request.fields['upload_preset'] = widget.uploadPreset;
      request.files.add(http.MultipartFile.fromBytes('file', fileBytes, filename: fileName));
      var response = await request.send().timeout(const Duration(seconds: 45));
      if (response.statusCode == 200) {
        var responseData = await response.stream.toBytes();
        var responseString = String.fromCharCodes(responseData);
        var jsonMap = jsonDecode(responseString);
        return jsonMap['secure_url']; 
      } else {
        return null;
      }
    } catch (e) {
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
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
                // Dynamic status message so the user sees live progress
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _statusMessage,
                    key: ValueKey(_statusMessage),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF6366F1), fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Please do not close the app.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.white38),
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
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10))],
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
                    const SizedBox(height: 16),
                    // Inform the user about the password email
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.2)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.mark_email_read_outlined, color: Color(0xFF6366F1), size: 20),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "A welcome email with your account password has been sent to your inbox.",
                              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── HR Approval Notice ───────────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFF59E0B).withOpacity(0.12),
                            const Color(0xFFF97316).withOpacity(0.08),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFF59E0B).withOpacity(0.35),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF59E0B).withOpacity(0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B).withOpacity(0.18),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.shield_outlined,
                                  color: Color(0xFFF59E0B),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  "Awaiting HR Approval",
                                  style: TextStyle(
                                    color: Color(0xFFF59E0B),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "Your application is now under review by our HR team. Once verified, you will receive full access to your DataTricks AI portal.",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.55,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFF59E0B).withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.mail_outline_rounded, color: Color(0xFFF59E0B), size: 16),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: RichText(
                                    text: const TextSpan(
                                      style: TextStyle(fontSize: 12, height: 1.5, color: Colors.white54),
                                      children: [
                                        TextSpan(text: "For any approval enquiries, please contact our HR team directly at "),
                                        TextSpan(
                                          text: "hr@datatricksai.us",
                                          style: TextStyle(
                                            color: Color(0xFFF59E0B),
                                            fontWeight: FontWeight.w700,
                                            decoration: TextDecoration.underline,
                                            decorationColor: Color(0xFFF59E0B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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

  void _showShareOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        title: const Row(
          children: [
            Icon(Icons.share, color: Color(0xFF6366F1)),
            SizedBox(width: 10),
            Text("Share Careers Form", style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy, color: Colors.white70),
              title: const Text("Copy Link", style: TextStyle(color: Colors.white)),
              onTap: () {
                Clipboard.setData(const ClipboardData(text: "https://datatricksai.us/careers"));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("Link copied to clipboard!", style: TextStyle(fontWeight: FontWeight.bold)),
                    backgroundColor: const Color(0xFF6366F1),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined, color: Colors.white70),
              title: const Text("Share via...", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                Share.share(
                  'Apply for AI roles using the DataTricks AI Careers Form: https://datatricksai.us/careers',
                  subject: 'DataTricks AI Careers Form',
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), 
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isMobile = width < 600;
            final isNarrow = width < 420;
            final horizontalPadding = isMobile ? 16.0 : 40.0;

            return Container(
              height: 70,
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))), 
                color: Colors.black.withOpacity(0.2),
              ), 
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                children: [
                  Flexible(
                    child: InkWell(
                      onTap: onHomeTap, 
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset('assets/images/logo.png', height: isMobile ? 32 : 40, errorBuilder: (c, e, s) => const Icon(Icons.rocket, color: Colors.white)), 
                          const SizedBox(width: 12), 
                          if (!isNarrow)
                            Flexible(
                              child: Text(
                                "DATATRICKS AI",
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: isMobile ? 15 : 20),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ), 
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      isMobile
                          ? IconButton(
                              onPressed: () => _showShareOptions(context),
                              icon: const Icon(Icons.share, color: Colors.white54, size: 20),
                              tooltip: "Share",
                            )
                          : TextButton.icon(
                              onPressed: () => _showShareOptions(context), 
                              icon: const Icon(Icons.share, color: Colors.white54, size: 18), 
                              label: const Text("Share", style: TextStyle(color: Colors.white54)),
                            ),
                      SizedBox(width: isMobile ? 4 : 20),
                      isMobile
                          ? IconButton(
                              onPressed: onHomeTap,
                              icon: const Icon(Icons.arrow_back, color: Colors.white54, size: 20),
                              tooltip: "Return Home",
                            )
                          : TextButton.icon(
                              onPressed: onHomeTap, 
                              icon: const Icon(Icons.arrow_back, color: Colors.white54, size: 18), 
                              label: const Text("Return Home", style: TextStyle(color: Colors.white54)),
                            ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// RESPONSIVE FIELD ROW — lays fields side-by-side on wide screens and
// stacks them vertically on narrow/mobile screens, avoiding RenderFlex
// overflow when field content (e.g. long state/region names) gets tight.
// ---------------------------------------------------------------------------
class _ResponsiveFieldRow extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double breakpoint;

  const _ResponsiveFieldRow({
    required this.children,
    this.spacing = 20,
    this.breakpoint = 700,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < breakpoint;
        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1) SizedBox(height: spacing),
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < children.length; i++) ...[
              Expanded(child: children[i]),
              if (i != children.length - 1) SizedBox(width: spacing),
            ],
          ],
        );
      },
    );
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
    this.isOptional = false,
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
        errorStyle: const TextStyle(color: Colors.redAccent, height: 1),
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

  const _NeonDropdown({
    required this.label, 
    required this.value, 
    required this.items, 
    required this.onChanged, 
    this.isOptional = false,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value, 
      isExpanded: true,
      items: items
          .map((e) => DropdownMenuItem(
                value: e,
                child: Text(
                  e,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ))
          .toList(), 
      selectedItemBuilder: (context) => items
          .map((e) => Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  e,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(color: Colors.white),
                ),
              ))
          .toList(),
      onChanged: onChanged, 
      dropdownColor: const Color(0xFF1E293B), 
      style: const TextStyle(color: Colors.white),
      validator: (val) {
        if (isOptional) return null;
        return val == null ? "Please select an option" : null;
      },
      decoration: InputDecoration(
        labelText: label, 
        labelStyle: const TextStyle(color: Colors.white38), 
        filled: true, 
        fillColor: Colors.white.withOpacity(0.05), 
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none), 
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF6366F1))), 
        errorStyle: const TextStyle(color: Colors.redAccent),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const _GradientButton({required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12), 
        gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFEC4899)], begin: Alignment.topLeft, end: Alignment.bottomRight), 
        boxShadow: const [BoxShadow(color: Color(0xFF6366F1), blurRadius: 20, offset: Offset(0, 5), spreadRadius: -5)],
      ), 
      child: ElevatedButton(
        onPressed: onPressed, 
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent, 
          shadowColor: Colors.transparent, 
          padding: const EdgeInsets.symmetric(vertical: 22), 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ), 
        child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
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
    final gridPaint = Paint()..color = Colors.white.withOpacity(0.02)..strokeWidth = 1;
    for (double i = 0; i < size.width; i += 50) canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    for (double i = 0; i < size.height; i += 50) canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}