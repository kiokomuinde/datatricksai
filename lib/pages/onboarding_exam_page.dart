import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ===========================================================================
// DATATRICKS AI — ONBOARDING EXAM PAGE  (v2)
// 18 Multiple-Choice  +  2 Written questions
// Total time: 60 minutes  |  Results marked later by HR — no answers revealed
// Firestore: collection('applications').where('email', ...)
// Constructor: OnboardingExamPage(userEmail: widget.userEmail)
// ===========================================================================

// ── Shared palette ──────────────────────────────────────────────────────────
const _bgTop         = Color(0xFFF8FAFC);
const _bgBot         = Color(0xFFE2E8F0);
const _glassWhite    = Color(0xB3FFFFFF);
const _glassBorder   = Color(0xFFFFFFFF);
const _primary       = Color(0xFF3B82F6);
const _primaryLight  = Color(0xFFEFF6FF);
const _secondary     = Color(0xFF10B981);
const _green         = Color(0xFF10B981);
const _greenLight    = Color(0xFFD1FAE5);
const _amber         = Color(0xFFF59E0B);
const _amberLight    = Color(0xFFFEF3C7);
const _red           = Color(0xFFEF4444);
const _redLight      = Color(0xFFFEE2E2);
const _textPrimary   = Color(0xFF0F172A);
const _textSecondary = Color(0xFF475569);
const _textMuted     = Color(0xFF94A3B8);
const _indigo        = Color(0xFF6366F1);
const _violet        = Color(0xFF8B5CF6);
const _sky           = Color(0xFF0EA5E9);

// ===========================================================================
// DATA MODELS
// ===========================================================================

class _MCQQuestion {
  final String question;
  final List<String> options;
  final IconData icon;

  const _MCQQuestion({
    required this.question,
    required this.options,
    required this.icon,
  });
}

class _WrittenQuestion {
  final String question;
  final String hint;
  final IconData icon;
  final int minutes;

  const _WrittenQuestion({
    required this.question,
    required this.hint,
    required this.icon,
    required this.minutes,
  });
}

// ===========================================================================
// 18 MULTIPLE-CHOICE QUESTIONS  — DataTricks AI Roles
// NOTE: Correct answers are intentionally hidden from users.
//       Results are determined and communicated by HR after review.
// ===========================================================================

const List<_MCQQuestion> _mcqQuestions = [

  // Q1 — Data Annotator (Text)
  _MCQQuestion(
    question: 'A Text Data Annotator at DataTricks AI receives a paragraph with ambiguous sentiment. What is the most appropriate action?',
    options: [
      'Label it as positive to maintain a balanced dataset',
      'Skip the sample and move to the next task',
      'Apply the closest matching label and add a confidence flag or note for review',
      'Mark it as negative because ambiguous content leans negative by default',
    ],
    icon: Icons.text_fields_rounded,
  ),

  // Q2 — AI Model Evaluator
  _MCQQuestion(
    question: 'As an AI Model Evaluator, which of the following best reflects a high-quality evaluation of an AI response?',
    options: [
      'Rating it highly if it is long and detailed, regardless of accuracy',
      'Assessing accuracy, relevance, safety, coherence, and adherence to instructions holistically',
      'Approving any response that sounds confident and professional',
      'Comparing the response to your personal preferences and scoring accordingly',
    ],
    icon: Icons.fact_check_rounded,
  ),

  // Q3 — Prompt Engineer
  _MCQQuestion(
    question: 'A Prompt Engineer is designing an instruction for a language model to summarise legal documents. Which prompt approach is most effective?',
    options: [
      '"Summarise this." — brief prompts reduce confusion',
      '"You are a legal assistant. Summarise the following document in 3 bullet points, focusing on key obligations and deadlines."',
      '"Please try to give a nice summary if you can."',
      '"Write everything you know about the document in detail."',
    ],
    icon: Icons.edit_note_rounded,
  ),

  // Q4 — Reinforcement Learning Feedback Specialist
  _MCQQuestion(
    question: 'A Reinforcement Learning Feedback Specialist is presented with two AI responses to the same prompt. Response A is helpful but slightly verbose. Response B is concise but misses a key fact. Which should be ranked higher?',
    options: [
      'Response B — shorter responses are always preferred in RLHF',
      'Response A — completeness and factual accuracy outweigh brevity',
      'Both should receive equal scores since neither is perfect',
      'Response B — missing facts can be corrected in later training rounds',
    ],
    icon: Icons.psychology_rounded,
  ),

  // Q5 — AI Trust & Safety Specialist
  _MCQQuestion(
    question: 'An AI Trust & Safety Specialist reviews a user query asking the model for advice on bypassing a school firewall. How should this be classified?',
    options: [
      'Safe — it is a legitimate technical question from a student',
      'Borderline — flag only if the user mentions malicious intent explicitly',
      'Unsafe — it involves circumventing security controls and should be refused',
      'Safe — firewalls are a general IT concept and the response is educational',
    ],
    icon: Icons.security_rounded,
  ),

  // Q6 — Data Quality Analyst
  _MCQQuestion(
    question: 'A Data Quality Analyst notices that 12% of labelled samples in a batch have inconsistent tags compared to the annotation guidelines. What is the correct first step?',
    options: [
      'Delete the inconsistent samples to clean the dataset quickly',
      'Relabel all 12% immediately without escalating',
      'Document the inconsistencies, isolate the affected samples, and escalate to the QA Lead with a full report',
      'Accept the batch — a 12% error rate is within normal tolerances for AI training data',
    ],
    icon: Icons.analytics_rounded,
  ),

  // Q7 — Content Moderator
  _MCQQuestion(
    question: 'A Content Moderator encounters a post that uses coded language commonly associated with hate speech but does not contain explicit slurs. How should this be handled?',
    options: [
      'Approve it — without explicit slurs it does not violate policy',
      'Escalate to a senior reviewer, citing the coded language pattern and relevant policy section',
      'Remove it immediately without documentation',
      'Warn the user and restore the content after 24 hours',
    ],
    icon: Icons.shield_rounded,
  ),

  // Q8 — Fact-Checker / Researcher
  _MCQQuestion(
    question: 'A Fact-Checker reviewing AI-generated content finds a statistic cited without a source. What is the correct protocol?',
    options: [
      'Accept the statistic if it seems reasonable and aligns with common knowledge',
      'Remove the entire paragraph containing the statistic',
      'Independently verify the claim against credible primary or secondary sources and flag it if unverifiable',
      'Replace the statistic with a rough estimate and mark it as approximate',
    ],
    icon: Icons.manage_search_rounded,
  ),

  // Q9 — Math / Logic Evaluator
  _MCQQuestion(
    question: 'A Math/Logic Evaluator is reviewing an AI solution to a multi-step algebra problem. The final answer is correct, but two intermediate steps contain errors. How should this be rated?',
    options: [
      'Highly — the correct final answer demonstrates sufficient reasoning',
      'Poorly — the intermediate errors indicate unreliable reasoning, even if the answer happens to be correct',
      'Neutrally — intermediate steps do not affect the quality of a math response',
      'Highly — minor intermediate errors are acceptable in AI-generated solutions',
    ],
    icon: Icons.calculate_rounded,
  ),

  // Q10 — Bias Mitigation Specialist
  _MCQQuestion(
    question: 'A Bias Mitigation Specialist discovers that a training dataset contains significantly more samples representing one demographic group than others. What is the most appropriate action?',
    options: [
      'Proceed — the majority group provides more reliable data for training',
      'Remove all samples from the over-represented group to balance the dataset immediately',
      'Recommend data augmentation or re-sampling strategies and document findings for the research team',
      'Report the imbalance only if it exceeds a 50% over-representation threshold',
    ],
    icon: Icons.balance_rounded,
  ),

  // Q11 — Audio Data Annotator
  _MCQQuestion(
    question: 'An Audio Data Annotator is transcribing a recording where a speaker has a strong regional accent and uses informal contractions. How should this be handled?',
    options: [
      'Transcribe in standard grammar, correcting contractions and pronunciation-based spelling',
      'Transcribe verbatim, preserving the speaker\'s exact words, contractions, and disfluencies per annotation guidelines',
      'Skip words that are unclear and insert "[inaudible]" for entire sentences',
      'Paraphrase the content to make it easier for the model to understand',
    ],
    icon: Icons.mic_rounded,
  ),

  // Q12 — Creative Writing Evaluator
  _MCQQuestion(
    question: 'A Creative Writing Evaluator reviews an AI-generated short story. The story is imaginative and well-structured, but contains a subtle glorification of self-harm. How should it be rated?',
    options: [
      'Highly — creative writing requires artistic freedom and dark themes are common in literature',
      'Neutrally — flag the theme but do not penalise the overall quality score',
      'Poorly — safety violations override creative quality; the content must be flagged and rejected',
      'It depends on whether the target audience is adults or minors',
    ],
    icon: Icons.draw_rounded,
  ),

  // Q13 — Code Review Specialist (LLM Training)
  _MCQQuestion(
    question: 'A Code Review Specialist evaluating AI-generated Python code notices the solution works correctly but uses a deprecated library function. What is the best evaluation action?',
    options: [
      'Mark it as fully correct — it works as intended',
      'Rate it poorly — only syntactically modern code is acceptable',
      'Mark it as functionally correct but note the deprecation as a quality issue, recommending the modern equivalent',
      'Rewrite the code yourself and submit the corrected version as the AI\'s output',
    ],
    icon: Icons.code_rounded,
  ),

  // Q14 — Transcription Specialist
  _MCQQuestion(
    question: 'A Transcription Specialist is working on a legal deposition audio file. A portion of the audio is distorted due to a technical issue. What should be done?',
    options: [
      'Guess the likely content based on context and transcribe accordingly',
      'Leave the section blank and continue',
      'Mark the segment with a standardised inaudible notation, note the timestamp, and flag for supervisory review',
      'Replay the audio at a higher volume and force-transcribe the distorted section',
    ],
    icon: Icons.record_voice_over_rounded,
  ),

  // Q15 — Multilingual Data Annotator
  _MCQQuestion(
    question: 'A Multilingual Data Annotator labelling Swahili text notices a phrase that is grammatically correct but would carry a strongly offensive connotation in a specific regional dialect. What is the correct response?',
    options: [
      'Label it as non-offensive since it is grammatically correct in standard Swahili',
      'Remove the phrase and substitute a neutral equivalent',
      'Label it appropriately per guidelines and add a regional dialect note, escalating for review if the guidelines do not cover this case',
      'Ignore it — regional dialect nuances are outside the scope of annotation tasks',
    ],
    icon: Icons.translate_rounded,
  ),

  // Q16 — Sentiment Analysis Evaluator
  _MCQQuestion(
    question: 'A Sentiment Analysis Evaluator reviews an AI label that classified a product review as "neutral." The review says: "The product arrived on time, which was the only good thing about it." What is the most accurate classification?',
    options: [
      'Positive — the reviewer mentions receiving the product on time',
      'Neutral — the sentence structure is balanced',
      'Negative — the overall sentiment is critical despite the one positive mention',
      'Mixed — split labels should be applied to each sentence separately',
    ],
    icon: Icons.sentiment_satisfied_alt_rounded,
  ),

  // Q17 — Red Teamer (AI Safety)
  _MCQQuestion(
    question: 'A Red Teamer is testing an AI model\'s resistance to jailbreak attempts. They craft a prompt disguised as a fictional scenario that attempts to extract instructions for creating dangerous materials. What is the primary goal of this exercise?',
    options: [
      'To generate harmful content for internal research archives',
      'To identify model vulnerabilities so they can be patched before deployment',
      'To demonstrate that the model can be bypassed and publish the findings publicly',
      'To compare the model\'s jailbreak resistance to competitor models for marketing purposes',
    ],
    icon: Icons.bug_report_rounded,
  ),

  // Q18 — Operations / General Professionalism
  _MCQQuestion(
    question: 'As a remote DataTricks AI contributor, you realise at 4:00 PM that you will not be able to complete your assigned batch before the 6:00 PM deadline due to a personal emergency. What is the most professional course of action?',
    options: [
      'Submit whatever is completed at 6:00 PM without any communication',
      'Miss the deadline silently and resume the batch the following morning',
      'Immediately notify your supervisor or task coordinator, explain the situation, submit completed work, and agree on a revised plan',
      'Ask a friend to complete the remaining tasks on your account to meet the deadline',
    ],
    icon: Icons.business_center_rounded,
  ),
];

// ===========================================================================
// 2 WRITTEN QUESTIONS  — 15 minutes each
// ===========================================================================

const List<_WrittenQuestion> _writtenQuestions = [
  _WrittenQuestion(
    question:
        'Describe your relevant experience, skills, and personal qualities that make you a strong candidate for your applied role at DataTricks AI. '
        'How would you ensure consistently high quality in your work, especially when managing repetitive or high-volume tasks?',
    hint: 'Mention specific skills, past experience, and your personal approach to quality and accuracy. Aim for at least 150 words.',
    icon: Icons.person_pin_rounded,
    minutes: 15,
  ),
  _WrittenQuestion(
    question:
        'Describe a situation — professional or academic — where you identified an error or quality issue that others had overlooked. '
        'What steps did you take to address it, what was the outcome, and what did you learn from the experience?',
    hint: 'Be specific about your role, the actions you took, and the results. Aim for at least 150 words.',
    icon: Icons.lightbulb_rounded,
    minutes: 15,
  ),
];

// Total questions
const int _totalMCQ     = 18;  // indices 0–17
const int _totalWritten = 2;   // indices 18–19
const int _totalQ       = _totalMCQ + _totalWritten; // 20
const int _examSeconds  = 60 * 60; // 60 minutes

// ===========================================================================
// EXAM STATES
// ===========================================================================

enum _ExamState { intro, inProgress, submitted }

// ===========================================================================
// MAIN PAGE WIDGET
// ===========================================================================

class OnboardingExamPage extends StatefulWidget {
  final String userEmail;
  const OnboardingExamPage({super.key, required this.userEmail});

  @override
  State<OnboardingExamPage> createState() => _OnboardingExamPageState();
}

class _OnboardingExamPageState extends State<OnboardingExamPage>
    with TickerProviderStateMixin {

  _ExamState _state        = _ExamState.intro;
  int        _currentIndex = 0; // 0–19

  // MCQ answers (indices 0–17 → selected option index, null = unanswered)
  final List<int?> _mcqAnswers = List.filled(_totalMCQ, null);

  // Written answers (indices 0–1)
  final List<TextEditingController> _writtenCtrl = [
    TextEditingController(),
    TextEditingController(),
  ];

  // Previous submission check
  bool      _loadingResult    = true;
  bool      _alreadySubmitted = false;
  bool      _isPendingReview  = false; // true when status == 'pending_review'

  // 90-day retake cooldown
  DateTime? _lastSubmittedAt;           // when they last submitted
  bool      _inCooldown       = false;  // true if < 90 days since submission
  Duration  _cooldownRemaining = Duration.zero;
  Timer?    _cooldownTicker;            // ticks every second for live countdown

  // Exam timer
  Timer?  _timer;
  int     _secondsLeft = _examSeconds;

  // Animations
  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;
  late AnimationController _slideCtrl;
  late Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    _fadeAnim  = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 340));
    _slideAnim = Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _fadeCtrl.forward();
    _loadPreviousResult();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cooldownTicker?.cancel();
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    for (final c in _writtenCtrl) c.dispose();
    super.dispose();
  }

  // ── Timer ─────────────────────────────────────────────────────────────────
  void _startTimer() {
    _secondsLeft = _examSeconds;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          t.cancel();
          _autoSubmit();
        }
      });
    });
  }

  String get _timerLabel {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft  %  60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Color get _timerColor {
    if (_secondsLeft <= 300) return _red;
    if (_secondsLeft <= 600) return _amber;
    return _green;
  }

  void _autoSubmit() {
    if (_state == _ExamState.inProgress) _finishExam(autoSubmit: true);
  }

  // ── Firestore: load previous submission + cooldown check ─────────────────
  Future<void> _loadPreviousResult() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('applications')
          .where('email', isEqualTo: widget.userEmail)
          .limit(1)
          .get();

      if (!mounted) return;
      if (snap.docs.isNotEmpty) {
        final data     = snap.docs.first.data();
        final examData = data['onboardingExam'] as Map<String, dynamic>?;
        if (examData != null) {
          final status = examData['status'] as String? ?? '';
          if (status == 'pending_review' || status == 'passed' || status == 'failed') {
            setState(() {
              _alreadySubmitted  = true;
              _isPendingReview   = (status == 'pending_review');
            });

            // Read submittedAt timestamp and compute 90-day cooldown
            final ts = examData['submittedAt'];
            if (ts != null && ts is Timestamp) {
              final submitted = ts.toDate();
              _lastSubmittedAt = submitted;
              final unlockAt   = submitted.add(const Duration(days: 90));
              final remaining  = unlockAt.difference(DateTime.now());
              if (remaining > Duration.zero) {
                _inCooldown        = true;
                _cooldownRemaining = remaining;
                _startCooldownTicker();
              }
            }
          }
        }
      }
    } catch (_) { /* silent */ }
    finally {
      if (mounted) setState(() => _loadingResult = false);
    }
  }

  // ── 90-day cooldown live ticker ───────────────────────────────────────────
  void _startCooldownTicker() {
    _cooldownTicker?.cancel();
    _cooldownTicker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_lastSubmittedAt == null) { t.cancel(); return; }

      final unlockAt  = _lastSubmittedAt!.add(const Duration(days: 90));
      final remaining = unlockAt.difference(DateTime.now());

      if (remaining <= Duration.zero) {
        t.cancel();
        if (mounted) setState(() {
          _inCooldown        = false;
          _cooldownRemaining = Duration.zero;
        });
      } else {
        if (mounted) setState(() => _cooldownRemaining = remaining);
      }
    });
  }

  // ── Cooldown display helpers ──────────────────────────────────────────────
  String get _cooldownLabel {
    final d  = _cooldownRemaining.inDays;
    final h  = _cooldownRemaining.inHours.remainder(24).toString().padLeft(2, '0');
    final m  = _cooldownRemaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s  = _cooldownRemaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${d}d  $h:$m:$s';
  }

  String get _unlockDateLabel {
    if (_lastSubmittedAt == null) return '';
    final d = _lastSubmittedAt!.add(const Duration(days: 90));
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String get _submittedDateLabel {
    if (_lastSubmittedAt == null) return '';
    final d = _lastSubmittedAt!;
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  // ── Firestore: save exam submission ──────────────────────────────────────
  Future<void> _saveSubmission() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('applications')
          .where('email', isEqualTo: widget.userEmail)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        await snap.docs.first.reference.update({
          'onboardingExam': {
            'status'      : 'pending_review',
            'mcqAnswers'  : _mcqAnswers,
            'writtenAnswer1': _writtenCtrl[0].text.trim(),
            'writtenAnswer2': _writtenCtrl[1].text.trim(),
            'totalQuestions': _totalQ,
            'mcqCount'    : _totalMCQ,
            'writtenCount': _totalWritten,
            'submittedAt' : FieldValue.serverTimestamp(),
          },
        });
      }
    } catch (_) { /* silent */ }
  }

  // ── Navigation helpers ────────────────────────────────────────────────────
  void _startExam() {
    if (_inCooldown) return; // locked during 90-day cooldown
    setState(() {
      _state        = _ExamState.inProgress;
      _currentIndex = 0;
      for (int i = 0; i < _totalMCQ; i++) _mcqAnswers[i] = null;
      _writtenCtrl[0].clear();
      _writtenCtrl[1].clear();
    });
    _startTimer();
    _animateIn();
  }

  void _animateIn() {
    _slideCtrl.forward(from: 0);
    _fadeCtrl.forward(from: 0.4);
  }

  bool get _isWrittenSection  => _currentIndex >= _totalMCQ;
  bool get _isMCQSection      => _currentIndex < _totalMCQ;
  int  get _writtenIndex      => _currentIndex - _totalMCQ; // 0 or 1

  bool get _currentAnswered {
    if (_isMCQSection) return _mcqAnswers[_currentIndex] != null;
    return _writtenCtrl[_writtenIndex].text.trim().isNotEmpty;
  }

  int get _answeredMCQ => _mcqAnswers.where((a) => a != null).length;

  bool get _canFinish {
    final allMCQ     = _answeredMCQ == _totalMCQ;
    final written1   = _writtenCtrl[0].text.trim().isNotEmpty;
    final written2   = _writtenCtrl[1].text.trim().isNotEmpty;
    return allMCQ && written1 && written2;
  }

  void _selectMCQ(int optionIndex) {
    if (_mcqAnswers[_currentIndex] != null) return; // already answered
    setState(() => _mcqAnswers[_currentIndex] = optionIndex);
  }

  void _nextQuestion() {
    if (_currentIndex < _totalQ - 1) {
      setState(() => _currentIndex++);
      _animateIn();
    } else {
      _finishExam();
    }
  }

  void _previousQuestion() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _animateIn();
    }
  }

  void _finishExam({bool autoSubmit = false}) {
    _timer?.cancel();
    setState(() {
      _alreadySubmitted = true;
      _isPendingReview  = true;
      _state = _ExamState.submitted;
    });
    _saveSubmission();
    _fadeCtrl.forward(from: 0);
  }

  // =========================================================================
  // BUILD
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    if (_loadingResult) return _buildLoader();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_bgTop, _bgBot],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: FadeTransition(
        opacity: _fadeAnim,
        child: () {
          switch (_state) {
            case _ExamState.intro:      return _buildIntro();
            case _ExamState.inProgress: return _buildExamScreen();
            case _ExamState.submitted:  return _buildSubmitted();
          }
        }(),
      ),
    );
  }

  // ── Loader ─────────────────────────────────────────────────────────────────
  Widget _buildLoader() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [_bgTop, _bgBot],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
    ),
    child: const Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        CircularProgressIndicator(color: _indigo, strokeWidth: 2.5),
        SizedBox(height: 14),
        Text('Loading exam…', style: TextStyle(color: _textSecondary, fontSize: 14)),
      ]),
    ),
  );

  // =========================================================================
  // INTRO SCREEN
  // =========================================================================

  Widget _buildIntro() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Hero card ─────────────────────────────────────────────────────
          _GlassCard(
            padding: EdgeInsets.zero,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(28, 36, 28, 32),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF4338CA), _indigo, _violet],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 70, height: 70,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.quiz_rounded, color: Colors.white, size: 32),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Onboarding Exam',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'DataTricks AI  ·  Contributor Certification',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.80),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Stats row
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Row(
                      children: [
                        const _StatPill(icon: Icons.quiz_outlined,         label: '20 Questions', color: _indigo),
                        _vDivider(),
                        const _StatPill(icon: Icons.timer_outlined,        label: '60 Minutes',   color: _sky),
                        _vDivider(),
                        const _StatPill(icon: Icons.rate_review_outlined,  label: 'HR Reviewed',  color: _amber),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Cooldown / already-submitted banner ───────────────────────────
          if (_alreadySubmitted) ...[
            if (_inCooldown) ...[
              // ── LOCKED: 90-day countdown card ─────────────────────────────
              _GlassCard(
                padding: EdgeInsets.zero,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    children: [
                      // Red gradient header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFB91C1C), _red, Color(0xFFF87171)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42, height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.lock_clock_rounded, color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Retake Locked',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'You must wait 90 days before retaking.',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Countdown body
                      Container(
                        color: _redLight.withValues(alpha: 0.55),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        child: Column(
                          children: [
                            // Big countdown display
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _red.withValues(alpha: 0.20), width: 1.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: _red.withValues(alpha: 0.08),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'RETAKE AVAILABLE IN',
                                    style: TextStyle(
                                      color: _textMuted,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    _cooldownLabel,
                                    style: const TextStyle(
                                      color: _red,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.5,
                                      fontFeatures: [FontFeature.tabularFigures()],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.event_rounded, color: _textMuted, size: 12),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Unlocks on $_unlockDateLabel',
                                        style: const TextStyle(
                                          color: _textMuted,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Submitted date info row
                            Row(
                              children: [
                                _CooldownInfoChip(
                                  icon: Icons.send_rounded,
                                  label: 'Submitted',
                                  value: _submittedDateLabel,
                                  color: _indigo,
                                ),
                                const SizedBox(width: 10),
                                _CooldownInfoChip(
                                  icon: Icons.hourglass_top_rounded,
                                  label: 'Cooldown',
                                  value: '90 days',
                                  color: _amber,
                                ),
                                const SizedBox(width: 10),
                                _CooldownInfoChip(
                                  icon: Icons.lock_open_rounded,
                                  label: 'Unlocks',
                                  value: _unlockDateLabel,
                                  color: _green,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // ── Cooldown expired — can retake ──────────────────────────────
              _GlassCard(
                color: _greenLight.withValues(alpha: 0.55),
                border: Border.all(color: _green.withValues(alpha: 0.30), width: 1.5),
                child: Row(children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(color: _green.withValues(alpha: 0.18), shape: BoxShape.circle),
                    child: const Icon(Icons.lock_open_rounded, color: _green, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text(
                        'Retake Now Available',
                        style: TextStyle(color: Color(0xFF065F46), fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '90 days have passed since your last submission on $_submittedDateLabel. You may retake the exam.',
                        style: const TextStyle(color: _textSecondary, fontSize: 12, height: 1.4),
                      ),
                    ]),
                  ),
                ]),
              ),
            ],
            const SizedBox(height: 16),
          ],

          // ── Pending Review banner (shown when status == pending_review) ──
          if (_isPendingReview) ...[
            _buildPendingReviewCard(),
            const SizedBox(height: 16),
          ],

          // ── Instructions card ─────────────────────────────────────────────
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionLabel(text: 'INSTRUCTIONS'),
                const SizedBox(height: 14),
                ..._introSteps.asMap().entries.map((e) => Padding(
                  padding: EdgeInsets.only(bottom: e.key < _introSteps.length - 1 ? 10 : 0),
                  child: _InstructionRow(number: '${e.key + 1}', text: e.value),
                )),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Exam structure card ───────────────────────────────────────────
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionLabel(text: 'EXAM STRUCTURE'),
                const SizedBox(height: 14),
                _StructureRow(
                  icon: Icons.radio_button_checked_rounded,
                  color: _indigo,
                  label: 'Section A — Multiple Choice',
                  detail: '18 questions  ·  ~30 minutes',
                ),
                const SizedBox(height: 10),
                _StructureRow(
                  icon: Icons.edit_rounded,
                  color: _sky,
                  label: 'Section B — Written Responses',
                  detail: '2 questions  ·  ~15 min each',
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Topics card ───────────────────────────────────────────────────
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionLabel(text: 'TOPICS COVERED'),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _topics.map((t) => _TopicChip(label: t.$1, icon: t.$2)).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── CTA ──────────────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: (_inCooldown || _isPendingReview) ? null : _startExam,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: (_inCooldown || _isPendingReview)
                      ? LinearGradient(
                          colors: [_textMuted.withValues(alpha: 0.35), _textMuted.withValues(alpha: 0.25)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        )
                      : const LinearGradient(
                          colors: [Color(0xFF4F46E5), _indigo, _violet],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: (_inCooldown || _isPendingReview)
                      ? []
                      : [
                          BoxShadow(
                            color: _indigo.withValues(alpha: 0.40),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _inCooldown
                          ? Icons.lock_rounded
                          : _isPendingReview
                              ? Icons.hourglass_top_rounded
                              : (_alreadySubmitted ? Icons.replay_rounded : Icons.play_arrow_rounded),
                      color: (_inCooldown || _isPendingReview) ? _textMuted : Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _inCooldown
                          ? 'Retake Locked — $_cooldownLabel'
                          : _isPendingReview
                              ? 'Result Pending — Retake Unavailable'
                              : (_alreadySubmitted ? 'Retake Exam' : 'Begin Exam'),
                      style: TextStyle(
                        color: (_inCooldown || _isPendingReview) ? _textMuted : Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: (_inCooldown || _isPendingReview) ? 14 : 16,
                        letterSpacing: 0.2,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Pending Review Card ───────────────────────────────────────────────────
  Widget _buildPendingReviewCard() {
    return _GlassCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [

            // ── Amber gradient header ─────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFB45309), _amber, Color(0xFFFCD34D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  // Pulsing icon container
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.20),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.hourglass_top_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Exam Under Processing',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            letterSpacing: -0.2,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Your submission is being reviewed by HR.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ──────────────────────────────────────────────────────
            Container(
              color: _amberLight.withValues(alpha: 0.50),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                children: [

                  // Status pill row
                  Row(
                    children: [
                      // Status chip
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _amber.withValues(alpha: 0.30), width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: _amber.withValues(alpha: 0.10),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _amber.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: _amber.withValues(alpha: 0.35), width: 1.0),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 7, height: 7,
                                      decoration: BoxDecoration(
                                        color: _amber,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(color: _amber.withValues(alpha: 0.50), blurRadius: 4),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'PENDING REVIEW',
                                      style: TextStyle(
                                        color: Color(0xFF92400E),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Your exam responses have been received and are currently queued for review by the DataTricks AI HR team.',
                                style: TextStyle(
                                  color: _textSecondary,
                                  fontSize: 12,
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Info chips row
                  Row(
                    children: [
                      _CooldownInfoChip(
                        icon: Icons.send_rounded,
                        label: 'Submitted',
                        value: _submittedDateLabel.isNotEmpty ? _submittedDateLabel : '—',
                        color: _indigo,
                      ),
                      const SizedBox(width: 10),
                      const _CooldownInfoChip(
                        icon: Icons.rate_review_rounded,
                        label: 'Status',
                        value: 'HR Review',
                        color: _amber,
                      ),
                      const SizedBox(width: 10),
                      const _CooldownInfoChip(
                        icon: Icons.mail_rounded,
                        label: 'Result Via',
                        value: 'Email',
                        color: _sky,
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Notice row
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.70),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _amber.withValues(alpha: 0.22), width: 1.0),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: _amber, size: 16),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'You will be notified by email once your result is ready. Please do not retake the exam unless instructed by HR.',
                            style: TextStyle(color: _textSecondary, fontSize: 11.5, height: 1.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _introSteps = [
    'Read each question carefully before selecting or writing your answer.',
    'Section A has 18 multiple-choice questions. Tap an option to lock in your answer — selections cannot be changed.',
    'Section B has 2 written questions (15 minutes each). Type your response in the text field provided.',
    'You have 60 minutes total. The exam will auto-submit when time runs out.',
    'You may navigate back to review previous answers using the Previous button.',
    'Results are NOT shown immediately. Your exam will be reviewed and marked by the HR team, who will contact you.',
    'Do not close the app during the exam — your progress is saved on submission only.',
  ];

  static const _topics = [
    ('Data Annotation',        Icons.label_outline),
    ('AI Evaluation',          Icons.fact_check_outlined),
    ('Prompt Engineering',     Icons.edit_note_outlined),
    ('Trust & Safety',         Icons.security_outlined),
    ('Data Quality',           Icons.analytics_outlined),
    ('RLHF Feedback',          Icons.psychology_outlined),
    ('Content Moderation',     Icons.shield_outlined),
    ('Fact-Checking',          Icons.manage_search_outlined),
    ('Bias & Ethics',          Icons.balance_outlined),
    ('Code Review',            Icons.code_outlined),
    ('Multilingual Work',      Icons.translate_outlined),
    ('Professionalism',        Icons.business_center_outlined),
  ];

  Widget _vDivider() => Container(
    width: 1, height: 36,
    color: _glassBorder,
    margin: const EdgeInsets.symmetric(horizontal: 4),
  );

  // =========================================================================
  // EXAM SCREEN (MCQ + Written)
  // =========================================================================

  Widget _buildExamScreen() {
    if (_isWrittenSection) return _buildWrittenQuestion();
    return _buildMCQQuestion();
  }

  // ── Progress header (shared) ──────────────────────────────────────────────
  Widget _buildProgressHeader() {
    final timerUrgent = _secondsLeft <= 300;

    return Container(
      color: _glassWhite,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Q ${_currentIndex + 1} of $_totalQ',
                style: const TextStyle(color: _textSecondary, fontWeight: FontWeight.w600, fontSize: 13),
              ),
              // Timer chip
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: _timerColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _timerColor.withValues(alpha: 0.35), width: 1.2),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                    timerUrgent ? Icons.timer_off_rounded : Icons.timer_rounded,
                    color: _timerColor, size: 14,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _timerLabel,
                    style: TextStyle(
                      color: _timerColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ]),
              ),
              // Answered count
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _indigo.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_answeredMCQ / $_totalMCQ MCQ',
                  style: const TextStyle(color: _indigo, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Segmented progress bar
          Row(
            children: List.generate(_totalQ, (i) {
              Color color;
              if (i < _totalMCQ) {
                if (_mcqAnswers[i] != null) {
                  color = _indigo;
                } else if (i == _currentIndex) {
                  color = _indigo.withValues(alpha: 0.35);
                } else {
                  color = _glassBorder;
                }
              } else {
                final wi = i - _totalMCQ;
                final filled = _writtenCtrl[wi].text.trim().isNotEmpty;
                if (filled) {
                  color = _sky;
                } else if (i == _currentIndex) {
                  color = _sky.withValues(alpha: 0.40);
                } else {
                  color = _glassBorder;
                }
              }
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── MCQ Question ──────────────────────────────────────────────────────────
  Widget _buildMCQQuestion() {
    final q        = _mcqQuestions[_currentIndex];
    final answered = _mcqAnswers[_currentIndex] != null;
    final isLast   = _currentIndex == _totalQ - 1;

    return Column(
      children: [
        _buildProgressHeader(),
        Expanded(
          child: SlideTransition(
            position: _slideAnim,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Section label
                    _GlassCard(
                      color: _indigo.withValues(alpha: 0.06),
                      border: Border.all(color: _indigo.withValues(alpha: 0.18), width: 1.2),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(children: [
                        const Icon(Icons.radio_button_checked_rounded, color: _indigo, size: 15),
                        const SizedBox(width: 8),
                        const Text(
                          'SECTION A — MULTIPLE CHOICE',
                          style: TextStyle(color: _indigo, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8),
                        ),
                        const Spacer(),
                        Text(
                          'Q${_currentIndex + 1} of $_totalMCQ',
                          style: const TextStyle(color: _indigo, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ]),
                    ),

                    const SizedBox(height: 14),

                    // Question card
                    _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF4F46E5), _violet],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: Icon(q.icon, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Question ${_currentIndex + 1}',
                                  style: const TextStyle(color: _indigo, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.5),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            q.question,
                            style: const TextStyle(
                              color: _textPrimary, fontSize: 16, fontWeight: FontWeight.w700, height: 1.5, letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Options — no correct/wrong reveal
                    ...q.options.asMap().entries.map((entry) {
                      final idx      = entry.key;
                      final text     = entry.value;
                      final selected = _mcqAnswers[_currentIndex] == idx;

                      return GestureDetector(
                        onTap: answered ? null : () => _selectMCQ(idx),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                          decoration: BoxDecoration(
                            color: selected
                                ? _indigo.withValues(alpha: 0.08)
                                : _glassWhite,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? _indigo.withValues(alpha: 0.55)
                                  : _glassBorder,
                              width: selected ? 1.8 : 1.5,
                            ),
                            boxShadow: selected
                                ? [BoxShadow(color: _indigo.withValues(alpha: 0.12), blurRadius: 8, offset: const Offset(0, 3))]
                                : [],
                          ),
                          child: Row(
                            children: [
                              // Option badge
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 30, height: 30,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? _indigo.withValues(alpha: 0.15)
                                      : _indigo.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: selected
                                        ? _indigo.withValues(alpha: 0.55)
                                        : _indigo.withValues(alpha: 0.18),
                                    width: 1.2,
                                  ),
                                ),
                                child: Center(
                                  child: selected
                                      ? const Icon(Icons.check_rounded, color: _indigo, size: 16)
                                      : Text(
                                          String.fromCharCode(65 + idx),
                                          style: const TextStyle(color: _indigo, fontWeight: FontWeight.w800, fontSize: 12),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  text,
                                  style: TextStyle(
                                    color: selected ? _textPrimary : _textSecondary,
                                    fontSize: 14,
                                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    // Notice — no answer reveal
                    if (answered) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: _primaryLight.withValues(alpha: 0.70),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _primary.withValues(alpha: 0.20), width: 1.2),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.lock_clock_rounded, color: _primary, size: 15),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Answer recorded. Results will be revealed after HR review.',
                                style: TextStyle(color: _primary, fontSize: 12, fontWeight: FontWeight.w600, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Nav buttons
                    _buildNavButtons(
                      isLast: isLast,
                      canProceed: answered,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Written Question ──────────────────────────────────────────────────────
  Widget _buildWrittenQuestion() {
    final wi        = _writtenIndex; // 0 or 1
    final q         = _writtenQuestions[wi];
    final isLast    = _currentIndex == _totalQ - 1;
    final hasText   = _writtenCtrl[wi].text.trim().isNotEmpty;
    final wordCount = _writtenCtrl[wi].text.trim().isEmpty
        ? 0
        : _writtenCtrl[wi].text.trim().split(RegExp(r'\s+')).length;

    return Column(
      children: [
        _buildProgressHeader(),
        Expanded(
          child: SlideTransition(
            position: _slideAnim,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Section label
                    _GlassCard(
                      color: _sky.withValues(alpha: 0.06),
                      border: Border.all(color: _sky.withValues(alpha: 0.25), width: 1.2),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(children: [
                        const Icon(Icons.edit_rounded, color: _sky, size: 15),
                        const SizedBox(width: 8),
                        const Text(
                          'SECTION B — WRITTEN RESPONSE',
                          style: TextStyle(color: _sky, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8),
                        ),
                        const Spacer(),
                        Text(
                          'Q${_currentIndex + 1} of $_totalQ  ·  ~${q.minutes} min',
                          style: const TextStyle(color: _sky, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ]),
                    ),

                    const SizedBox(height: 14),

                    // Question card
                    _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [_sky, Color(0xFF0284C7)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: Icon(q.icon, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Question ${_currentIndex + 1}',
                                      style: const TextStyle(color: _sky, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.5),
                                    ),
                                    Text(
                                      'Written  ·  ~${q.minutes} minutes',
                                      style: const TextStyle(color: _textMuted, fontSize: 11, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            q.question,
                            style: const TextStyle(
                              color: _textPrimary, fontSize: 15, fontWeight: FontWeight.w700, height: 1.55, letterSpacing: -0.1,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Text input area
                    Container(
                      decoration: BoxDecoration(
                        color: _glassWhite,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: hasText ? _sky.withValues(alpha: 0.50) : _glassBorder,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10, offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                            child: TextField(
                              controller: _writtenCtrl[wi],
                              maxLines: 10,
                              minLines: 8,
                              keyboardType: TextInputType.multiline,
                              textCapitalization: TextCapitalization.sentences,
                              style: const TextStyle(
                                color: _textPrimary, fontSize: 14, height: 1.6,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: q.hint,
                                hintStyle: TextStyle(
                                  color: _textMuted.withValues(alpha: 0.80),
                                  fontSize: 13, height: 1.5,
                                ),
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          // Word count footer
                          Container(
                            padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                            child: Row(
                              children: [
                                Icon(Icons.text_snippet_outlined, color: _textMuted, size: 13),
                                const SizedBox(width: 5),
                                Text(
                                  '$wordCount words',
                                  style: const TextStyle(color: _textMuted, fontSize: 11, fontWeight: FontWeight.w500),
                                ),
                                const Spacer(),
                                if (wordCount < 50 && wordCount > 0)
                                  Text(
                                    'Aim for at least 150 words',
                                    style: TextStyle(color: _amber.withValues(alpha: 0.80), fontSize: 11, fontWeight: FontWeight.w600),
                                  )
                                else if (wordCount >= 150)
                                  Row(children: [
                                    Icon(Icons.check_circle_outline_rounded, color: _green, size: 12),
                                    const SizedBox(width: 4),
                                    const Text('Good length', style: TextStyle(color: _green, fontSize: 11, fontWeight: FontWeight.w600)),
                                  ]),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Confidentiality note
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: _amberLight.withValues(alpha: 0.60),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _amber.withValues(alpha: 0.25), width: 1.2),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.rate_review_rounded, color: _amber, size: 14),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Your written responses will be reviewed and scored by the DataTricks AI HR team.',
                              style: TextStyle(color: Color(0xFF92400E), fontSize: 12, fontWeight: FontWeight.w600, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Nav buttons
                    _buildNavButtons(
                      isLast: isLast,
                      canProceed: hasText,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Shared nav buttons ────────────────────────────────────────────────────
  Widget _buildNavButtons({required bool isLast, required bool canProceed}) {
    final canSubmit = isLast && _canFinish;

    return Row(
      children: [
        if (_currentIndex > 0) ...[
          Expanded(
            flex: 1,
            child: GestureDetector(
              onTap: _previousQuestion,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _glassWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _glassBorder, width: 1.5),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_back_rounded, color: _textSecondary, size: 18),
                    SizedBox(width: 6),
                    Text('Previous', style: TextStyle(color: _textSecondary, fontWeight: FontWeight.w700, fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: isLast
                ? (canSubmit ? _finishExam : null)
                : (canProceed ? _nextQuestion : null),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: (isLast ? canSubmit : canProceed)
                    ? const LinearGradient(
                        colors: [Color(0xFF4F46E5), _indigo, _violet],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      )
                    : LinearGradient(
                        colors: [_textMuted.withValues(alpha: 0.20), _textMuted.withValues(alpha: 0.15)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: (isLast ? canSubmit : canProceed)
                    ? [BoxShadow(color: _indigo.withValues(alpha: 0.30), blurRadius: 12, offset: const Offset(0, 4))]
                    : [],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isLast ? 'Submit Exam' : 'Next',
                    style: TextStyle(
                      color: (isLast ? canSubmit : canProceed) ? Colors.white : _textMuted,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    isLast ? Icons.send_rounded : Icons.arrow_forward_rounded,
                    color: (isLast ? canSubmit : canProceed) ? Colors.white : _textMuted,
                    size: 17,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // SUBMITTED SCREEN
  // =========================================================================

  Widget _buildSubmitted() => SingleChildScrollView(
    padding: const EdgeInsets.all(28),
    child: Column(
      children: [

        // ── Hero ──────────────────────────────────────────────────────────
        _GlassCard(
          padding: EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(28, 40, 28, 36),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0369A1), _sky, Color(0xFF38BDF8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      Stack(alignment: Alignment.center, children: [
                        Container(
                          width: 90, height: 90,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.10),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 66, height: 66,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.mark_email_read_rounded, color: Colors.white, size: 30),
                        ),
                      ]),
                      const SizedBox(height: 20),
                      const Text(
                        'Exam Submitted!',
                        style: TextStyle(
                          color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'DataTricks AI  ·  Onboarding Certification',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.80),
                          fontSize: 13, fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Stats row
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Row(
                    children: [
                      const _StatPill(icon: Icons.quiz_outlined,      label: '20 Answered',   color: _indigo),
                      _vDivider(),
                      const _StatPill(icon: Icons.pending_outlined,   label: 'Under Review',  color: _amber),
                      _vDivider(),
                      const _StatPill(icon: Icons.mail_outline_rounded, label: 'Result by Email', color: _sky),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // ── What happens next ─────────────────────────────────────────────
        _GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionLabel(text: 'WHAT HAPPENS NEXT'),
              const SizedBox(height: 16),
              _NextStepRow(
                step: '1',
                icon: Icons.rate_review_rounded,
                color: _indigo,
                title: 'HR Review',
                detail: 'Your exam responses are being reviewed and marked by the DataTricks AI HR team.',
              ),
              const SizedBox(height: 12),
              _NextStepRow(
                step: '2',
                icon: Icons.mail_rounded,
                color: _sky,
                title: 'Result Notification',
                detail: 'You will receive an email with your results and next steps once the review is complete.',
              ),
              const SizedBox(height: 12),
              _NextStepRow(
                step: '3',
                icon: Icons.verified_rounded,
                color: _green,
                title: 'Onboarding',
                detail: 'Successful candidates will be contacted with onboarding instructions and task access.',
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── 90-day retake cooldown notice ─────────────────────────────────
        _GlassCard(
          color: _redLight.withValues(alpha: 0.45),
          border: Border.all(color: _red.withValues(alpha: 0.22), width: 1.5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(color: _red.withValues(alpha: 0.14), shape: BoxShape.circle),
                  child: const Icon(Icons.lock_clock_rounded, color: _red, size: 19),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      '90-Day Retake Cooldown',
                      style: TextStyle(color: Color(0xFF991B1B), fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Your next retake will be available after 90 days.',
                      style: TextStyle(color: _textSecondary, fontSize: 12, height: 1.4),
                    ),
                  ]),
                ),
              ]),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _red.withValues(alpha: 0.18), width: 1.2),
                ),
                child: Column(children: [
                  const Text(
                    'RETAKE UNLOCKS IN',
                    style: TextStyle(color: _textMuted, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _inCooldown ? _cooldownLabel : 'Unlocked!',
                    style: TextStyle(
                      color: _inCooldown ? _red : _green,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (_unlockDateLabel.isNotEmpty)
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.event_rounded, color: _textMuted, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'Unlocks on $_unlockDateLabel',
                        style: const TextStyle(color: _textMuted, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ]),
                ]),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Confirmation notice ───────────────────────────────────────────
        _GlassCard(
          color: _greenLight.withValues(alpha: 0.50),
          border: Border.all(color: _green.withValues(alpha: 0.25), width: 1.5),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: _green.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_outline_rounded, color: _green, size: 22),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Responses Saved', style: TextStyle(color: Color(0xFF065F46), fontWeight: FontWeight.w800, fontSize: 13)),
                SizedBox(height: 3),
                Text(
                  'Your exam has been securely saved. Do not retake the exam unless instructed to do so by HR.',
                  style: TextStyle(color: _textSecondary, fontSize: 12, height: 1.4),
                ),
              ]),
            ),
          ]),
        ),

        const SizedBox(height: 32),
      ],
    ),
  );

  Widget _vDivider2() => Container(width: 1, height: 40, color: _glassBorder);
}

// =============================================================================
// HELPER WIDGETS
// =============================================================================

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final BoxBorder? border;

  const _GlassCard({required this.child, this.padding, this.color, this.border});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, spreadRadius: 1, offset: const Offset(0, 4)),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color ?? _glassWhite,
            borderRadius: BorderRadius.circular(16),
            border: border ?? Border.all(color: _glassBorder, width: 1.5),
          ),
          child: child,
        ),
      ),
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(color: _textMuted, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2),
  );
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatPill({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 18),
      ),
      const SizedBox(height: 6),
      Text(label, style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.w700, fontSize: 12), textAlign: TextAlign.center),
    ]),
  );
}

class _TopicChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _TopicChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: _indigo.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _indigo.withValues(alpha: 0.20), width: 1.2),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: _indigo, size: 13),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(color: _indigo, fontSize: 11, fontWeight: FontWeight.w700)),
    ]),
  );
}

class _InstructionRow extends StatelessWidget {
  final String number, text;
  const _InstructionRow({required this.number, required this.text});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 24, height: 24,
        decoration: BoxDecoration(
          color: _indigo.withValues(alpha: 0.10),
          shape: BoxShape.circle,
          border: Border.all(color: _indigo.withValues(alpha: 0.30), width: 1.2),
        ),
        child: Center(child: Text(number, style: const TextStyle(color: _indigo, fontWeight: FontWeight.w800, fontSize: 11))),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(text, style: const TextStyle(color: _textSecondary, fontSize: 13, height: 1.5)),
        ),
      ),
    ],
  );
}

class _StructureRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label, detail;
  const _StructureRow({required this.icon, required this.color, required this.label, required this.detail});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(9)),
        child: Icon(icon, color: color, size: 18),
      ),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
        Text(detail, style: const TextStyle(color: _textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
      ]),
    ],
  );
}

class _NextStepRow extends StatelessWidget {
  final String step, title, detail;
  final IconData icon;
  final Color color;
  const _NextStepRow({required this.step, required this.title, required this.detail, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
        child: Center(child: Text(step, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 14))),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Text(title, style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.w800, fontSize: 13)),
          ]),
          const SizedBox(height: 3),
          Text(detail, style: const TextStyle(color: _textSecondary, fontSize: 12, height: 1.4)),
        ]),
      ),
    ],
  );
}

class _CooldownInfoChip extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _CooldownInfoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.22), width: 1.2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: TextStyle(color: color.withValues(alpha: 0.70), fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.8),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
  );
}