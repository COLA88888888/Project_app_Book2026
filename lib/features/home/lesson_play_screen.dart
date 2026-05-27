import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/database/db_helper.dart';
import '../../core/models/lesson.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'dart:io';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class LessonPlayScreen extends StatefulWidget {
  final String lessonId;

  const LessonPlayScreen({super.key, required this.lessonId});

  @override
  State<LessonPlayScreen> createState() => _LessonPlayScreenState();
}

class QuizQuestion {
  final String questionText;
  final List<String> options;
  final int correctIndex;
  final String? readingGuide;

  QuizQuestion({
    required this.questionText,
    required this.options,
    required this.correctIndex,
    this.readingGuide,
  });
}

class _LessonPlayScreenState extends State<LessonPlayScreen> {
  Lesson? lesson;
  bool isLoading = true;
  int currentQuestionIndex = 0;
  int selectedOptionIndex = -1;
  bool showFeedback = false;
  bool isAnswerCorrect = false;
  int score = 0;
  int currentUserId = 0;
  List<QuizQuestion> questions = [];
  final Set<int> _failedOptionIndices = {};
  bool _hadMistake = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;
  bool _isLaoAvailable = false;
  bool get isReadingMode => lesson != null && lesson!.grade == 'P1' && lesson!.subject == 'ການອ່ານ';
  bool _isMicRecording = false;
  bool _hasReadCurrent = false;
  bool _isCheckingLao = true;

  // Speech to Text related state variables
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isSpeechAvailable = false;
  bool _isSpeechListening = false;
  String _recognizedWords = '';
  bool _showSelfVerification = false;
  bool _showIncorrectGuide = false;

  @override
  void initState() {
    super.initState();
    _loadLesson();
    _initTtsPlayer();
    _initSpeechRecognition();
  }

  void _initTtsPlayer() async {
    try {
      // Check if Lao voice is available on this device
      dynamic avail = await _flutterTts.isLanguageAvailable("lo-LA");
      bool laoOk = (avail == true || avail == 1);
      if (!laoOk) {
        avail = await _flutterTts.isLanguageAvailable("lo");
        laoOk = (avail == true || avail == 1);
      }

      if (laoOk) {
        await _flutterTts.setLanguage("lo-LA");
        await _flutterTts.setPitch(1.35); // Sound like a child
        await _flutterTts.setSpeechRate(0.5);
        await _flutterTts.setVolume(1.0);
      }

      if (mounted) {
        setState(() {
          _isLaoAvailable = laoOk;
          _isCheckingLao = false;
        });
      }
    } catch (e) {
      debugPrint('Error initializing FlutterTts: $e');
      if (mounted) setState(() => _isCheckingLao = false);
    }
  }

  void _initSpeechRecognition() async {
    try {
      bool available = await _speech.initialize(
        onStatus: (status) {
          debugPrint('Speech recognition status: $status');
          if (status == 'done' || status == 'notListening') {
            if (mounted && _isSpeechListening) {
              _stopSpeechListeningAndVerify();
            }
          }
        },
        onError: (errorNotification) {
          debugPrint('Speech recognition error: ${errorNotification.errorMsg}');
          if (mounted && _isSpeechListening) {
            _stopSpeechListeningAndVerify();
          }
        },
      );
      if (mounted) {
        setState(() {
          _isSpeechAvailable = available;
        });
      }
    } catch (e) {
      debugPrint('Speech recognition initialization failed: $e');
    }
  }

  void _startSpeechListening() async {
    if (!_isSpeechAvailable) {
      // Speech recognition not available, fallback to manual parent/self-verification simulator.
      setState(() {
        _isMicRecording = true;
        _isSpeechListening = false;
        _hasReadCurrent = false;
        _recognizedWords = '';
        _showIncorrectGuide = false;
        _showSelfVerification = false;
      });

      // Simulate a 3-second pulsing audio record
      Future.delayed(const Duration(milliseconds: 3000), () {
        if (mounted) {
          setState(() {
            _isMicRecording = false;
            _showSelfVerification = true; // Show self/parent-verification card!
          });
        }
      });
      return;
    }

    setState(() {
      _isMicRecording = true;
      _isSpeechListening = true;
      _hasReadCurrent = false;
      _recognizedWords = '';
      _showIncorrectGuide = false;
      _showSelfVerification = false;
    });

    try {
      await _speech.listen(
        onResult: (result) {
          if (mounted) {
            setState(() {
              _recognizedWords = result.recognizedWords;
            });

            // Real-time voice recognition check!
            final currentQuestion = questions[currentQuestionIndex];
            final target = currentQuestion.questionText;
            bool correct = _verifyPronunciation(target, _recognizedWords);

            if (correct) {
              // Halts listening immediately upon correct pronunciation!
              _speech.stop();
              setState(() {
                _isMicRecording = false;
                _isSpeechListening = false;
                _hasReadCurrent = true;
                _showIncorrectGuide = false;
              });
              _playCorrectSound();
            }
          }
        },
        // ignore: deprecated_member_use
        localeId: 'lo_LA',
        // ignore: deprecated_member_use
        listenFor: const Duration(seconds: 5),
        // ignore: deprecated_member_use
        pauseFor: const Duration(seconds: 3),
      );

      // Force-stop listening after 5 seconds to analyze if not stopped automatically
      Future.delayed(const Duration(milliseconds: 5000), () {
        if (mounted && _isSpeechListening) {
          _stopSpeechListeningAndVerify();
        }
      });
    } catch (e) {
      debugPrint('Error listening: $e');
      if (mounted) {
        setState(() {
          _isMicRecording = false;
          _isSpeechListening = false;
          _showSelfVerification = true; // Graceful fallback
        });
      }
    }
  }

  void _stopSpeechListeningAndVerify() async {
    if (!_isSpeechListening) return;

    try {
      await _speech.stop();
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isMicRecording = false;
        _isSpeechListening = false;
      });
      _verifySpeechInput();
    }
  }

  void _verifySpeechInput() {
    final currentQuestion = questions[currentQuestionIndex];
    final target = currentQuestion.questionText;

    bool correct = _verifyPronunciation(target, _recognizedWords);

    if (correct) {
      setState(() {
        _hasReadCurrent = true;
        _showIncorrectGuide = false;
      });
      _playCorrectSound();
    } else {
      setState(() {
        _hasReadCurrent = false;
        _showIncorrectGuide = true;
      });
      _playIncorrectSound();
      _speakIncorrectPrompt(target);
    }
  }

  void _speakIncorrectPrompt(String text) async {
    if (_isLaoAvailable) {
      try {
        await _flutterTts.stop();
        await _flutterTts.speak("ຫຼານລອງອ່ານອອກສຽງຄືນໃໝ່ວ່າ $text");
      } catch (_) {}
    }
  }

  bool _verifyPronunciation(String target, String recognized) {
    if (recognized.isEmpty) return false;
    
    // Normalize string by removing emojis, spaces, and converting to standard Lao
    String cleanTarget = _normalizeLaoText(target);
    String cleanRecognized = _normalizeLaoText(recognized);
    
    debugPrint('Verifying pronunciation: Target="$cleanTarget", Recognized="$cleanRecognized"');
    
    if (cleanRecognized.contains(cleanTarget)) return true;
    
    // Check reading guide phonetic clues.
    final currentQuestion = questions[currentQuestionIndex];
    if (currentQuestion.readingGuide != null) {
      List<String> phoneticWords = [];
      if (target == 'ກ') phoneticWords.addAll(['ໄກ່', 'ກໍ', 'ກໍໄກ່']);
      if (target == 'ຂ') phoneticWords.addAll(['ໄຂ່', 'ຂໍ', 'ຂໍໄຂ່']);
      if (target == 'ຄ') phoneticWords.addAll(['ຄວາຍ', 'ຄໍ', 'ຄໍຄວາຍ']);
      if (target == 'ງ') phoneticWords.addAll(['ງູ', 'ງໍ', 'ງໍງູ']);
      if (target == 'ຈ') phoneticWords.addAll(['ຈອກ', 'ຈໍ', 'ຈໍຈອກ']);
      if (target == 'ສ') phoneticWords.addAll(['ເສືອ', 'ສໍ', 'ສໍເສືອ']);
      if (target == 'ຊ') phoneticWords.addAll(['ຊ້າງ', 'ຊໍ', 'ຊໍຊ້າງ']);
      if (target == 'ຍ') phoneticWords.addAll(['ຍຸງ', 'ຍໍ', 'ຍໍຍຸງ']);
      if (target == 'ດ') phoneticWords.addAll(['ເດັກ', 'ດໍ', 'ດໍເດັກ', 'ເດັກນ້ອຍ']);
      if (target == 'ຕ') phoneticWords.addAll(['ຕາ', 'ຕໍ', 'ຕໍຕາ']);
      if (target == 'ຖ') phoneticWords.addAll(['ຖົງ', 'ຖໍ', 'ຖໍຖົງ']);
      if (target == 'ທ') phoneticWords.addAll(['ທຸງ', 'ທໍ', 'ທໍທຸງ']);
      if (target == 'ນ') phoneticWords.addAll(['ນົກ', 'ນໍ', 'ນໍນົກ']);
      if (target == 'ບ') phoneticWords.addAll(['ແບ້', 'ບໍ', 'ບໍແບ້']);
      if (target == 'ປ') phoneticWords.addAll(['ປາ', 'ປໍ', 'ປໍປາ']);
      if (target == 'ຜ') phoneticWords.addAll(['ເຜິ້ງ', 'ຜໍ', 'ຜໍເຜິ້ງ']);
      if (target == 'ຝ') phoneticWords.addAll(['ຝົນ', 'ຝໍ', 'ຝໍຝົນ']);
      if (target == 'ພ') phoneticWords.addAll(['ພູ', 'ພໍ', 'ພໍພູ']);
      if (target == 'ຟ') phoneticWords.addAll(['ໄຟ', 'ຟໍ', 'ຟໍໄຟ']);
      if (target == 'ມ') phoneticWords.addAll(['ແມວ', 'ມໍ', 'ມໍແມວ']);
      if (target == 'ຢ') phoneticWords.addAll(['ຢາ', 'ຢໍ', 'ຢໍຢາ']);
      if (target == 'ຣ') phoneticWords.addAll(['ຣົດ', 'ຣໍ', 'ຣໍຣົດ', 'ລົດ']);
      if (target == 'ລ') phoneticWords.addAll(['ລີງ', 'ລໍ', 'ລໍລີງ']);
      if (target == 'ວ') phoneticWords.addAll(['ວີ', 'ວໍ', 'ວໍວີ']);
      if (target == 'ຫ') phoneticWords.addAll(['ຫ່ານ', 'ຫໍ', 'ຫໍຫ່ານ']);
      if (target == 'ອ') phoneticWords.addAll(['ໂອ', 'ອໍ', 'ອໍໂອ']);
      if (target == 'ຮ') phoneticWords.addAll(['ເຮືອນ', 'ຮໍ', 'ຮໍເຮືອນ']);

      for (var word in phoneticWords) {
        if (cleanRecognized.contains(_normalizeLaoText(word))) {
          return true;
        }
      }
    }
    
    return false;
  }

  String _normalizeLaoText(String text) {
    return text
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'[.,\/#!$%\^&\*;:{}=\-_`~()?🌶️🐔🥚🐃🐍🐦🦵👩‍🏫👁️✏️🐘🦟🎨🙋‍♂️🚩👜🌾🎀🦀👻🏠👨⚡🚗🐒⛵👂📖😆🏫🐐🌲🏔️🐕🐈]'), '')
        .replaceAll(RegExp(r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]', unicode: true), '')
        .trim();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _speakQuestion(String text) async {
    // If Lao TTS not installed, guide user to download it
    if (!_isLaoAvailable) {
      _showInstallLaoTtsDialog();
      return;
    }

    if (_isSpeaking) {
      try {
        await _flutterTts.stop();
      } catch (_) {}
      setState(() => _isSpeaking = false);
      return;
    }

    setState(() => _isSpeaking = true);

    try {
      // Strip emojis for cleaner pronunciation
      final cleanText = text.replaceAll(
          RegExp(
              r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]',
              unicode: true),
          '');

      await _flutterTts.setLanguage("lo-LA");
      await _flutterTts.setPitch(1.35);
      await _flutterTts.setSpeechRate(0.5);

      _flutterTts.setCompletionHandler(() {
        if (mounted) setState(() => _isSpeaking = false);
      });

      _flutterTts.setErrorHandler((msg) {
        debugPrint('FlutterTts Error: \$msg');
        if (mounted) setState(() => _isSpeaking = false);
      });

      await _flutterTts.speak(cleanText);
    } catch (e) {
      debugPrint('Error speaking via FlutterTts: \$e');
      if (mounted) setState(() => _isSpeaking = false);
    }
  }

  /// Shows a guide explaining that Lao TTS is not in Google engine
  void _showInstallLaoTtsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _LaoTtsInstallSheet(
        onOpenPlayStore: () {
          Navigator.pop(ctx);
          _openPlayStoreForLaoTts();
        },
        onOpenSettings: () {
          Navigator.pop(ctx);
          _openTtsSettings();
        },
        onClose: () => Navigator.pop(ctx),
      ),
    );
  }

  /// Opens Play Store searching for Lao TTS apps
  Future<void> _openPlayStoreForLaoTts() async {
    try {
      if (Platform.isAndroid) {
        try {
          const AndroidIntent intent = AndroidIntent(
            action: 'android.intent.action.VIEW',
            data: 'market://search?q=lao+tts+voice&c=apps',
          );
          await intent.launch();
        } catch (_) {
          const AndroidIntent intent = AndroidIntent(
            action: 'android.intent.action.VIEW',
            data: 'https://play.google.com/store/search?q=lao+tts+voice&c=apps',
          );
          await intent.launch();
        }
      }
    } catch (e) {
      debugPrint('Error opening Play Store: \$e');
    }
  }

  /// Opens the Android TTS Settings screen
  Future<void> _openTtsSettings() async {
    try {
      if (Platform.isAndroid) {
        const AndroidIntent intent = AndroidIntent(
          action: 'com.android.settings.TTS_SETTINGS',
        );
        await intent.launch();
      }
    } catch (e) {
      debugPrint('Error opening TTS settings: \$e');
    }
  }

  Future<void> _loadLesson() async {
    final id = int.tryParse(widget.lessonId);
    if (id == null) return;

    final allLessons = await DatabaseHelper.instance.getAllLessons();
    final matched = allLessons.firstWhere((l) => l.id == id);

    final title = matched.title;

    _populateQuestions(title);

    final prefs = await SharedPreferences.getInstance();
    currentUserId = prefs.getInt('current_user_id') ?? 1;

    setState(() {
      lesson = matched;
      isLoading = false;
    });
  }

  void _populateQuestions(String title) {
    if (title.contains('ບົດທີ 9: ປະສົມພະຍັນຊະນະ ກັບ ສະຫຼະສຽງສັ້ນ xະ, xິ, xຶ, xຸ 🍎')) {
      questions = [
        QuizQuestion(
          questionText: 'ກ + ະ = ?',
          options: ['ກາ', 'ກະ 🌸', 'ກິ', 'ກຶ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຈ + ຸ = ?',
          options: ['ຈະ', 'ຈິ', 'ຈຶ', 'ຈຸ 🖊️'],
          correctIndex: 3,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ສຶ" ປະກອບດ້ວຍ...?',
          options: ['ສ + xະ', 'ສ + xິ', 'ສ + xຶ 🐯', 'ສ + xຸ'],
          correctIndex: 2,
        ),
      ];
    } else if (title.contains('ບົດທີ 10: ປະສົມພະຍັນຊະນະ ກັບ ສະຫຼະສຽງຍາວ xາ, xີ, xື, xູ 🌾')) {
      questions = [
        QuizQuestion(
          questionText: 'ດ + ີ = ? 👍',
          options: ['ດາ', 'ດີ 👍', 'ດື', 'ດູ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ປ + ູ = ? 🦀',
          options: ['ປາ', 'ປີ', 'ປື', 'ປູ 🦀'],
          correctIndex: 3,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ມື" ປະກອບດ້ວຍ...?',
          options: ['ມ + xາ', 'ມ + xີ', 'ມ + xື ✋', 'ມ + xູ'],
          correctIndex: 2,
        ),
      ];
    } else if (title.contains('ບົດທີ 11: ປະສົມພະຍັນຊະນະ ກັບ ສະຫຼະ ເx, ແx, ໂx, xໍ 🎀')) {
      questions = [
        QuizQuestion(
          questionText: 'ບ + ໂx = ?',
          options: ['ເບ', 'ແບ', 'ໂບ 🐂', 'ບໍ'],
          correctIndex: 2,
        ),
        QuizQuestion(
          questionText: 'ປ + xໍ = ?',
          options: ['ເປ', 'ແປ', 'ໂປ', 'ປໍ 💎'],
          correctIndex: 3,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ແບ" ປະກອບດ້ວຍ...?',
          options: ['ບ + ເx', 'ບ + ແx 🐐', 'ບ + ໂx', 'ບ + xໍ'],
          correctIndex: 1,
        ),
      ];
    } else if (title.contains('ບົດທີ 12: ປະສົມພະຍັນຊະນະ ກັບ ສະຫຼະພິເສດ xຳ, ໄx, ໃx, ເxົາ 🔥')) {
      questions = [
        QuizQuestion(
          questionText: 'ລ + xຳ = ?',
          options: ['ໄລ', 'ໃລ', 'ລຳ 💃', 'ເລົາ'],
          correctIndex: 2,
        ),
        QuizQuestion(
          questionText: 'ຟ + ໄx = ?',
          options: ['ຟຳ', 'ໄຟ 🔥', 'ໃຟ', 'ເຟົາ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ໃບ" ປະກອບດ້ວຍ...?',
          options: ['ບ + xຳ', 'ບ + ໄx', 'ບ + ໃx 🍃', 'ບ + ເxົາ'],
          correctIndex: 2,
        ),
      ];
    } else if (title.contains('ບົດທີ 13: ປະສົມພະຍັນຊະນະ ກັບ ອັກສອນປະສົມ ຫງ, ຫຍ, ໜ, ໝ, ຫຼ, ຫວ 🐶') || title.contains('ປະສົມພະຍັນຊະນະ ກັບ ອັກສອນປະສົມ')) {
      questions = [
        QuizQuestion(
          questionText: 'ໝ + າ = ?',
          options: ['ໜາ', 'ໝາ 🐶', 'ຫຼາ', 'ຫວາ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຫຼ + ີ = ?',
          options: ['ຫຼິ', 'ຫຼີ 👦', 'ໜິ', 'ໜີ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ໜູ" ປະກອບດ້ວຍ...?',
          options: ['ໜ + xູ 🐭', 'ໝ + xູ', 'ຫຼ + xູ', 'ຫວ + xູ'],
          correctIndex: 0,
        ),
      ];
    } else if (title.contains('ບົດທີ 14: ປະສົມພະຍັນຊະນະ ກັບ ວັນນະຍຸດ ໄມ້ເອກ (x່) ແລະ ໄມ້ໂທ (x້) 🌲') || title.contains('ປະສົມພະຍັນຊະນະ ກັບ ວັນນະຍຸດ')) {
      questions = [
        QuizQuestion(
          questionText: 'ປ + າ + ໄມ້ເອກ (x່) = ?',
          options: ['ປາ', 'ປ່າ 🌲', 'ປ້າ', 'ປ໊າ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ມ + າ + ໄມ້ໂທ (x້) = ?',
          options: ['ມາ', 'ມ່າ', 'ມ້າ 🐎', 'ມ໊າ'],
          correctIndex: 2,
        ),
        QuizQuestion(
          questionText: 'ພ + ໍ + ໄມ້ເອກ (x່) = ?',
          options: ['ພໍ', 'ພໍ່ 👨', 'ພໍ້', 'ພ໊ໍ'],
          correctIndex: 1,
        ),
      ];
    } else if (title.contains('ບົດທີ 1: ອ່ານພະຍັນຊະນະ ກ, ຂ, ຄ, ງ')) {
      questions = [
        QuizQuestion(questionText: 'ກ', options: [], correctIndex: -1, readingGuide: 'ພະຍັນຊະນະ ກ (ກໍ) 🐔'),
        QuizQuestion(questionText: 'ຂ', options: [], correctIndex: -1, readingGuide: 'ພະຍັນຊະນະ ຂ (ຂໍ) 🥚'),
        QuizQuestion(questionText: 'ຄ', options: [], correctIndex: -1, readingGuide: 'ພະຍັນຊະນະ ຄ (ຄໍ) 🐃'),
        QuizQuestion(questionText: 'ງ', options: [], correctIndex: -1, readingGuide: 'ພະຍັນຊະນະ ງ (ງໍ) 🐍'),
        QuizQuestion(questionText: 'ກາ', options: [], correctIndex: -1, readingGuide: 'ກ + າ = ກາ 🐦'),
        QuizQuestion(questionText: 'ຂາ', options: [], correctIndex: -1, readingGuide: 'ຂ + າ = ຂາ 🦵'),
        QuizQuestion(questionText: 'ຄູ', options: [], correctIndex: -1, readingGuide: 'ຄ + ູ = ຄູ 👩‍🏫'),
        QuizQuestion(questionText: 'ງູ', options: [], correctIndex: -1, readingGuide: 'ງ + ູ = ງູ 🐍'),
      ];
    } else if (title.contains('ບົດທີ 2: ອ່ານພະຍັນຊະນະ ຈ, ສ, ຊ, ຍ')) {
      questions = [
        QuizQuestion(questionText: 'ຈ', options: [], correctIndex: -1, readingGuide: 'ພະຍັນຊະນະ ຈ (ຈໍ) 👁️'),
        QuizQuestion(questionText: 'ສ', options: [], correctIndex: -1, readingGuide: 'ພະຍັນຊະນະ ສ (ສໍ) ✏️'),
        QuizQuestion(questionText: 'ຊ', options: [], correctIndex: -1, readingGuide: 'ພະຍັນຊະນະ ຊ (ຊໍ) 🐘'),
        QuizQuestion(questionText: 'ຍ', options: [], correctIndex: -1, readingGuide: 'ພະຍັນຊະນະ ຍ (ຍໍ) 🦟'),
        QuizQuestion(questionText: 'ຈາ', options: [], correctIndex: -1, readingGuide: 'ຈ + າ = ຈາ 🗣️'),
        QuizQuestion(questionText: 'ສີ', options: [], correctIndex: -1, readingGuide: 'ສ + ີ = ສີ 🎨'),
        QuizQuestion(questionText: 'ຊູ', options: [], correctIndex: -1, readingGuide: 'ຊ + ູ = ຊູ 🙋‍♂️'),
        QuizQuestion(questionText: 'ຍຸ', options: [], correctIndex: -1, readingGuide: 'ຍ + ຸ = ຍຸ 🦟'),
      ];
    } else if (title.contains('ບົດທີ 3: ອ່ານພະຍັນຊະນະ ດ, ຕ, ຖ, ທ')) {
      questions = [
        QuizQuestion(questionText: 'ດ', options: [], correctIndex: -1, readingGuide: 'ພະຍັນຊະນະ ດ (ດໍ) 👶'),
        QuizQuestion(questionText: 'ຕ', options: [], correctIndex: -1, readingGuide: 'ພະຍັນຊະນະ ຕ (ຕໍ) 👁️'),
        QuizQuestion(questionText: 'ຖ', options: [], correctIndex: -1, readingGuide: 'ພະຍັນຊະນະ ຖ (ຖໍ) 👜'),
        QuizQuestion(questionText: 'ທ', options: [], correctIndex: -1, readingGuide: 'ພະຍັນຊະນະ ທ (ທໍ) 🚩'),
        QuizQuestion(questionText: 'ດີ', options: [], correctIndex: -1, readingGuide: 'ດ + ີ = ດີ 👍'),
        QuizQuestion(questionText: 'ຕາ', options: [], correctIndex: -1, readingGuide: 'ຕ + າ = ຕາ 👁️'),
        QuizQuestion(questionText: 'ຖູ', options: [], correctIndex: -1, readingGuide: 'ຖ + ູ = ຖູ 🧹'),
        QuizQuestion(questionText: 'ທາ', options: [], correctIndex: -1, readingGuide: 'ທ + າ = ທາ 🖌️'),
      ];
    } else if (title.contains('ບົດທີ 4: ອ່ານພະຍັນຊະນະ ນ, ບ, ປ, ຜ')) {
      questions = [
        QuizQuestion(questionText: 'ນ', options: [], correctIndex: -1, readingGuide: 'ພະຍັນຊະນະ ນ (ນໍ) 🐦'),
        QuizQuestion(questionText: 'ບ', options: [], correctIndex: -1, readingGuide: 'ພະຍັນຊະນະ ບ (ບໍ) 🐂'),
        QuizQuestion(questionText: 'ປ', options: [], correctIndex: -1, readingGuide: 'ພະຍັນຊະນະ ປ (ປໍ) 🐟'),
        QuizQuestion(questionText: 'ຜ', options: [], correctIndex: -1, readingGuide: 'ພະຍັນຊະນະ ຜ (ຜໍ) 🐝'),
        QuizQuestion(questionText: 'ນາ', options: [], correctIndex: -1, readingGuide: 'ນ + າ = ນາ 🌾'),
        QuizQuestion(questionText: 'ໂບ', options: [], correctIndex: -1, readingGuide: 'ບ + ໂx = ໂບ 🎀'),
        QuizQuestion(questionText: 'ປູ', options: [], correctIndex: -1, readingGuide: 'ປ + ູ = ປູ 🦀'),
        QuizQuestion(questionText: 'ຜີ', options: [], correctIndex: -1, readingGuide: 'ຜ + ີ = ຜີ 👻'),
      ];
    } else if (title.contains('ບົດທີ 5: ອ່ານພະຍັນຊະນະ ຝ, ພ, ຟ, ມ')) {
      questions = [
        QuizQuestion(questionText: 'ຝ', options: [], correctIndex: -1, readingGuide: 'ພະຍັນຊະນະ ຝ (ຝໍ) 🌧️'),
        QuizQuestion(questionText: 'ພ', options: [], correctIndex: -1, readingGuide: 'ພະຍັນຊະນະ ພ (ພໍ) 🌳'),
        QuizQuestion(questionText: 'ຟ', options: [], correctIndex: -1, readingGuide: 'ພະຍັນຊະນະ ຟ (ຟໍ) ⚡'),
        QuizQuestion(questionText: 'ມ', options: [], correctIndex: -1, readingGuide: 'ພະຍັນຊະນະ ມ (ມໍ) 🐈'),
        QuizQuestion(questionText: 'ຝາ', options: [], correctIndex: -1, readingGuide: 'ຝ + າ = ຝາ 🏠'),
        QuizQuestion(questionText: 'ພໍ່', options: [], correctIndex: -1, readingGuide: 'ພ + ໍ + ໄມ້ເອກ = ພໍ່ 👨'),
        QuizQuestion(questionText: 'ໄຟ', options: [], correctIndex: -1, readingGuide: 'ຟ + ໄx = ໄຟ 🔥'),
        QuizQuestion(questionText: 'ມື', options: [], correctIndex: -1, readingGuide: 'ມ + ື = ມື ✋'),
      ];
    } else if (title.contains('ບົດທີ 6: ອ່ານພະຍັນຊະນະ ຢ, ຣ, ລ, ວ')) {
      questions = [
        QuizQuestion(questionText: 'ຢ', options: [], correctIndex: -1, readingGuide: 'ພະຍັນຊະນະ ຢ (ຢໍ) 💊'),
        QuizQuestion(questionText: 'ຣ', options: [], correctIndex: -1, readingGuide: 'ພະຍັນຊະນະ ຣ (ຣໍ) 🚗'),
        QuizQuestion(questionText: 'ລ', options: [], correctIndex: -1, readingGuide: 'ພະຍັນຊະນະ ລ (ລໍ) 🐒'),
        QuizQuestion(questionText: 'ວ', options: [], correctIndex: -1, readingGuide: 'ພະຍັນຊະນະ ວ (ວໍ) 🐈'),
        QuizQuestion(questionText: 'ຢາ', options: [], correctIndex: -1, readingGuide: 'ຢ + າ = ຢາ 💊'),
        QuizQuestion(questionText: 'ເຮືອ', options: [], correctIndex: -1, readingGuide: 'ຮ + ເxືອ = ເຮືອ ⛵'),
        QuizQuestion(questionText: 'ລີ', options: [], correctIndex: -1, readingGuide: 'ລ + ີ = ລີ 🏃'),
        QuizQuestion(questionText: 'ເວົ້າ', options: [], correctIndex: -1, readingGuide: 'ວ + ເxົາ + ໄມ້ໂທ = ເວົ້າ 🗣️'),
      ];
    } else if (title.contains('ບົດທີ 7: ອ່ານພະຍັນຊະນະ ຫ, ອ, ຮ')) {
      questions = [
        QuizQuestion(questionText: 'ຫ', options: [], correctIndex: -1, readingGuide: 'ພະຍັນຊະນະ ຫ (ຫໍ) 📦'),
        QuizQuestion(questionText: 'ອ', options: [], correctIndex: -1, readingGuide: 'ພະຍັນຊະນະ ອ (ອໍ) 🛁'),
        QuizQuestion(questionText: 'ຮ', options: [], correctIndex: -1, readingGuide: 'ພະຍັນຊະນະ ຮ (ຮໍ) 🏠'),
        QuizQuestion(questionText: 'ຫູ', options: [], correctIndex: -1, readingGuide: 'ຫ + ູ = ຫູ 👂'),
        QuizQuestion(questionText: 'ອ່ານ', options: [], correctIndex: -1, readingGuide: 'ອ + າ + ນ + ໄມ້ເອກ = ອ່ານ 📖'),
        QuizQuestion(questionText: 'ຮາ', options: [], correctIndex: -1, readingGuide: 'ຮ + າ = ຮາ 😆'),
      ];
    } else if (title.contains('ບົດທີ 8: ທວນຄືນອ່ານພະຍັນຊະນະ ກ ຮອດ ຮ')) {
      questions = [
        QuizQuestion(questionText: 'ກ', options: [], correctIndex: -1, readingGuide: 'ກໍ ໄກ່ 🐔'),
        QuizQuestion(questionText: 'ຂ', options: [], correctIndex: -1, readingGuide: 'ຂໍ ໄຂ່ 🥚'),
        QuizQuestion(questionText: 'ຄ', options: [], correctIndex: -1, readingGuide: 'ຄໍ ຄວາຍ 🐃'),
        QuizQuestion(questionText: 'ງ', options: [], correctIndex: -1, readingGuide: 'ງໍ ງູ 🐍'),
        QuizQuestion(questionText: 'ຈ', options: [], correctIndex: -1, readingGuide: 'ຈໍ ຈອກ 🥛'),
        QuizQuestion(questionText: 'ສ', options: [], correctIndex: -1, readingGuide: 'ສໍ ເສືອ 🐯'),
        QuizQuestion(questionText: 'ຊ', options: [], correctIndex: -1, readingGuide: 'ຊໍ ຊ້າງ 🐘'),
        QuizQuestion(questionText: 'ຍ', options: [], correctIndex: -1, readingGuide: 'ຍໍ ຍຸງ 🦟'),
        QuizQuestion(questionText: 'ດ', options: [], correctIndex: -1, readingGuide: 'ດໍ ເດັກ 👶'),
        QuizQuestion(questionText: 'ຕ', options: [], correctIndex: -1, readingGuide: 'ຕໍ ຕາ 👁️'),
        QuizQuestion(questionText: 'ຖ', options: [], correctIndex: -1, readingGuide: 'ຖໍ ຖົງ 👜'),
        QuizQuestion(questionText: 'ທ', options: [], correctIndex: -1, readingGuide: 'ທໍ ທຸງ 🚩'),
        QuizQuestion(questionText: 'ນ', options: [], correctIndex: -1, readingGuide: 'ນໍ ນົກ 🐦'),
        QuizQuestion(questionText: 'ບ', options: [], correctIndex: -1, readingGuide: 'ບໍ ແບ້ 🐐'),
        QuizQuestion(questionText: 'ປ', options: [], correctIndex: -1, readingGuide: 'ປໍ ປາ 🐟'),
        QuizQuestion(questionText: 'ຜ', options: [], correctIndex: -1, readingGuide: 'ຜໍ ເຜິ້ງ 🐝'),
        QuizQuestion(questionText: 'ຝ', options: [], correctIndex: -1, readingGuide: 'ຝໍ ຝົນ 🌧️'),
        QuizQuestion(questionText: 'ພ', options: [], correctIndex: -1, readingGuide: 'ພໍ ພູ ⛰️'),
        QuizQuestion(questionText: 'ຟ', options: [], correctIndex: -1, readingGuide: 'ຟໍ ໄຟ 🔥'),
        QuizQuestion(questionText: 'ມ', options: [], correctIndex: -1, readingGuide: 'ມໍ ແມວ 🐈'),
        QuizQuestion(questionText: 'ຢ', options: [], correctIndex: -1, readingGuide: 'ຢໍ ຢາ 💊'),
        QuizQuestion(questionText: 'ຣ', options: [], correctIndex: -1, readingGuide: 'ຣໍ ຣົດ 🚗'),
        QuizQuestion(questionText: 'ລ', options: [], correctIndex: -1, readingGuide: 'ລໍ ລີງ 🐒'),
        QuizQuestion(questionText: 'ວ', options: [], correctIndex: -1, readingGuide: 'ວໍ ວີ 🪭'),
        QuizQuestion(questionText: 'ຫ', options: [], correctIndex: -1, readingGuide: 'ຫໍ ຫ່ານ 🪿'),
        QuizQuestion(questionText: 'ອ', options: [], correctIndex: -1, readingGuide: 'ອໍ ໂອ 🛁'),
        QuizQuestion(questionText: 'ຮ', options: [], correctIndex: -1, readingGuide: 'ຮໍ ເຮືອນ 🏠'),
      ];
    } else if (title.contains('ບົດທີ 9: ໂຈດອ່ານສະຫຼະສຽງສັ້ນ xະ, xິ, xຶ, xຸ') || title.contains('ໂຈດອ່ານ 6') || title.contains('ສະຫຼະສຽງສັ້ນ')) {
      questions = [
        QuizQuestion(questionText: 'xະ', options: [], correctIndex: -1, readingGuide: 'ສະຫຼະ xະ (ອະ) 🌸'),
        QuizQuestion(questionText: 'xິ', options: [], correctIndex: -1, readingGuide: 'ສະຫຼະ xິ (ອິ) 💧'),
        QuizQuestion(questionText: 'xຶ', options: [], correctIndex: -1, readingGuide: 'ສະຫຼະ xຶ (ອຶ) 🌀'),
        QuizQuestion(questionText: 'xຸ', options: [], correctIndex: -1, readingGuide: 'ສະຫຼະ xຸ (ອຸ) 🧸'),
        QuizQuestion(questionText: 'ຈະ', options: [], correctIndex: -1, readingGuide: 'ຈ + ະ = ຈະ 🌟'),
        QuizQuestion(questionText: 'ກິ', options: [], correctIndex: -1, readingGuide: 'ກ + ິ = ກິ 🍎'),
        QuizQuestion(questionText: 'ສຶ', options: [], correctIndex: -1, readingGuide: 'ສ + ຶ = ສຶ 🐯'),
        QuizQuestion(questionText: 'ຈຸ', options: [], correctIndex: -1, readingGuide: 'ຈ + ຸ = ຈຸ 🖊️'),
      ];
    } else if (title.contains('ບົດທີ 10: ໂຈດອ່ານສະຫຼະສຽງຍາວ xາ, xີ, xື, xູ') || title.contains('ໂຈດອ່ານ 7') || title.contains('ສະຫຼະສຽງຍາວ')) {
      questions = [
        QuizQuestion(questionText: 'xາ', options: [], correctIndex: -1, readingGuide: 'ສະຫຼະ xາ (ອາ) 🌾'),
        QuizQuestion(questionText: 'xີ', options: [], correctIndex: -1, readingGuide: 'ສະຫຼະ xີ (ອີ) 🎨'),
        QuizQuestion(questionText: 'xື', options: [], correctIndex: -1, readingGuide: 'ສະຫຼະ xື (ອື) ✋'),
        QuizQuestion(questionText: 'xູ', options: [], correctIndex: -1, readingGuide: 'ສະຫຼະ xູ (ອູ) 🦀'),
        QuizQuestion(questionText: 'ກາ', options: [], correctIndex: -1, readingGuide: 'ກ + າ = ກາ 🐦'),
        QuizQuestion(questionText: 'ດີ', options: [], correctIndex: -1, readingGuide: 'ດ + ີ = ດີ 👍'),
        QuizQuestion(questionText: 'ມື', options: [], correctIndex: -1, readingGuide: 'ມ + ື = ມື ✋'),
        QuizQuestion(questionText: 'ປູ', options: [], correctIndex: -1, readingGuide: 'ປ + ູ = ປູ 🦀'),
      ];
    } else if (title.contains('ບົດທີ 1: ພະຍັນຊະນະ ກ, ຂ, ຄ, ງ & ສະຫຼະ xະ, xາ')) {
      questions = [
        QuizQuestion(
          questionText: 'ກ + າ = ? 🐦',
          options: ['ກາ 🐦', 'ກະ 🌸', 'ກິ 💧', 'ກຶ 🌀'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຂ + ະ = ? 🌸',
          options: ['ຂາ 🦵', 'ຂະ 🌸', 'ຂິ 💧', 'ຂຶ 🌀'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ກາ" 🐦 ປະກອບດ້ວຍພະຍັນຊະນະ ແລະ ສະຫຼະໃດ?',
          options: ['ກ + xະ', 'ກ + xາ 🌾', 'ຂ + xະ', 'ຂ + xາ'],
          correctIndex: 1,
        ),
      ];
    } else if (title.contains('ບົດທີ 2: ພະຍັນຊະນະ ຈ, ສ, ຊ, ຍ & ສະຫຼະ xິ, xີ') || title.contains('ບົດທີ 2: ພະຍັນຊະນະ ຈ, ສ, ຊ, ຍ')) {
      questions = [
        QuizQuestion(
          questionText: 'ຈ + ີ = ? 👁️',
          options: ['ຈາ', 'ຈິ', 'ຈີ 👁️', 'ຈຶ'],
          correctIndex: 2,
        ),
        QuizQuestion(
          questionText: 'ສ + ິ = ? ✏️',
          options: ['ສາ', 'ສິ ✏️', 'ສີ', 'ສຶ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ຊິ" ປະກອບດ້ວຍພະຍັນຊະນະ ແລະ ສະຫຼະໃດ? 🐘',
          options: ['ຊ + xິ 🐘', 'ຊ + xີ', 'ຍ + xິ', 'ຍ + xີ'],
          correctIndex: 0,
        ),
      ];
    } else if (title.contains('ບົດທີ 3: ພະຍັນຊະນະ ດ, ຕ, ຖ, ທ & ສະຫຼະ xຶ, xື')) {
      questions = [
        QuizQuestion(
          questionText: 'ດ + ຶ = ? 👶',
          options: ['ດຶ 👶', 'ດື', 'ດິ', 'ດີ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຕ + ື = ? 👁️',
          options: ['ຕຶ', 'ຕື 👁️', 'ຕິ', 'ຕີ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ທຶ" ປະກອບດ້ວຍພະຍັນຊະນະ ແລະ ສະຫຼະໃດ? 🚩',
          options: ['ທ + xຶ 🚩', 'ທ + xື', 'ຖ + xຶ', 'ຖ + xື'],
          correctIndex: 0,
        ),
      ];
    } else if (title.contains('ບົດທີ 4: ພະຍັນຊະນະ ນ, ບ, ປ, ຜ & ສະຫຼະ xຸ, xູ')) {
      questions = [
        QuizQuestion(
          questionText: 'ປ + ູ = ? 🦀',
          options: ['ປຸ', 'ປູ 🦀', 'ຜຸ', 'ຜູ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ນ + ຸ = ? 🐦',
          options: ['ນຸ 🐦', 'ນູ', 'ບຸ', 'ບູ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ບູ" ປະກອບດ້ວຍພະຍັນຊະນະ ແລະ ສະຫຼະໃດ? 🐂',
          options: ['ບ + xຸ', 'ບ + xູ 🐂', 'ນ + xຸ', 'ນ + xູ'],
          correctIndex: 1,
        ),
      ];
    } else if (title.contains('ບົດທີ 5: ພະຍັນຊະນະ ຝ, ພ, ຟ, ມ & ສະຫຼະ ເx, ແx')) {
      questions = [
        QuizQuestion(
          questionText: 'ມ + ເx = ? 🐈',
          options: ['ເມະ', 'ເມ 🐈', 'ແມະ', 'ແມ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຟ + ແx = ? ⚡',
          options: ['ເຟ', 'ແຟ ⚡', 'ເຟະ', 'ແຟະ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ເຝ" ປະກອບດ້ວຍພະຍັນຊະນະ ແລະ ສະຫຼະໃດ? 🌧️',
          options: ['ຝ + ເx 🌧️', 'ຝ + ແx', 'ພ + ເx', 'ພ + ແx'],
          correctIndex: 0,
        ),
      ];
    } else if (title.contains('ບົດທີ 6: ພະຍັນຊະນະ ຢ, ຣ, ລ, ວ & ສະຫຼະ ໂx, xໍ')) {
      questions = [
        QuizQuestion(
          questionText: 'ລ + ໂx = ? 🐒',
          options: ['ໂລະ', 'ໂລ 🐒', 'ລໍ', 'ເລະ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ວ + xໍ = ? 🐈',
          options: ['ໂວ', 'ວໍ 🐈', 'ໂວະ', 'ແວ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ໂຢ" ປະກອບດ້ວຍພະຍັນຊະນະ ແລະ ສະຫຼະໃດ? 💊',
          options: ['ຢ + ໂx 💊', 'ຢ + ໂxະ', 'ຣ + ໂx', 'ຣ + ໂxະ'],
          correctIndex: 0,
        ),
      ];
    } else if (title.contains('ບົດທີ 7: ພະຍັນຊະນະ ຫ, ອ, ຮ & ສະຫຼະ xຳ, ໄx, ໃx, ເxົາ')) {
      questions = [
        QuizQuestion(
          questionText: 'ຫ + ໃx = ? 📦',
          options: ['ໃຫ 📦', 'ໄຫ', 'ຫຳ', 'ເຫົາ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ອ + ເxົາ = ? 🛁',
          options: ['ອຳ', 'ໄອ', 'ໃອ', 'ເອົາ 🛁'],
          correctIndex: 3,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ໄຮ" ປະກອບດ້ວຍພະຍັນຊະນະ ແລະ ສະຫຼະໃດ? 🏠',
          options: ['ຮ + ໄx 🏠', 'ຮ + ໃx', 'ຫ + ໄx', 'ຫ + ໃx'],
          correctIndex: 0,
        ),
      ];
    } else if (title.contains('ບົດທີ 8: ທວນຄືນປະສົມພະຍັນຊະນະ ກ ຮອດ ຮ')) {
      questions = [
        QuizQuestion(
          questionText: 'ກ + າ = ? 🐦',
          options: ['ກາ 🐦', 'ຂາ', 'ຄາ', 'ງາ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຈ + ີ = ? 👁️',
          options: ['ຈິ', 'ຈີ 👁️', 'ສິ', 'ສີ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ດ + ີ = ? 👍',
          options: ['ດາ', 'ດີ 👍', 'ຕາ', 'ຕີ'],
          correctIndex: 1,
        ),
      ];

    } else if (title.contains('ພະຍັນຊະນະຄວບ ກວ, ຄວ, ຂວ')) {
      questions = [
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ກວາດ" 🧹 ອອກສຽງພະຍັນຊະນະຄວບໃດ?',
          options: ['ກວ', 'ຄວ', 'ຂວ', 'ຊວ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ຄວາຍ" 🐃 ອອກສຽງພະຍັນຊະນະຄວບໃດ?',
          options: ['ກວ', 'ຄວ', 'ຂວ', 'ຊວ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ຂວານ" 🪓 ອອກສຽງພະຍັນຊະນະຄວບໃດ?',
          options: ['ກວ', 'ຄວ', 'ຂວ', 'ຊວ'],
          correctIndex: 2,
        ),
      ];
    } else if (title.contains('ຕົວສະກົດທັງ 8')) {
      questions = [
        QuizQuestion(
          questionText: 'ຕົວສະກົດໃນພາສາລາວມີທັງໝົດຈັກຕົວ? 🔢',
          options: ['6 ຕົວ', '7 ຕົວ', '8 ຕົວ', '9 ຕົວ'],
          correctIndex: 2,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ຮຽນ" 📖 ປະກອບດ້ວຍຕົວສະກົດໃດ?',
          options: ['ຕົວສະກົດ ນ', 'ຕົວສະກົດ ກ', 'ຕົວສະກົດ ງ', 'ຕົວສະກົດ ມ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ແລ່ນ" 🏃 ປະກອບດ້ວຍຕົວສະກົດໃດ?',
          options: ['ຕົວສະກົດ ນ', 'ຕົວສະກົດ ກ', 'ຕົວສະກົດ ບ', 'ຕົວສະກົດ ງ'],
          correctIndex: 0,
        ),
      ];
    } else if (title.contains('ຄຳນາມ, ຄຳແທນນາມ')) {
      questions = [
        QuizQuestion(
          questionText: 'ຄຳໃດຕໍ່ໄປນີ້ແມ່ນ "ຄຳນາມ" (ຊື່ເອີ້ນ)? 🎒',
          options: ['ປຶ້ມ', 'ແລ່ນ', 'ຂ້ອຍ', 'ໃຫຍ່'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຄຳໃດຕໍ່ໄປນີ້ແມ່ນ "ຄຳກຳມະ" (ສະແດງການກະທຳ)? 🏃',
          options: ['ແລ່ນ', 'ປຶ້ມ', 'ຂ້ອຍ', 'ງາມ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ຂ້ອຍ" 🙋 ແມ່ນຄຳປະເພດໃດ? 🌟',
          options: ['ຄຳແທນນາມ', 'ຄຳນາມ', 'ຄຳກຳມະ', 'ຄຳຄຸນນາມ'],
          correctIndex: 0,
        ),
      ];
    } else if (title.contains('ການອ່ານບົດເລື່ອງສັ້ນ')) {
      questions = [
        QuizQuestion(
          questionText: 'ຖ້າບົດເລື່ອງເວົ້າວ່າ "ແມ່ເຮັດອາຫານແຊບຫຼາຍ", ໃຜເປັນຄົນເຮັດອາຫານ? 🍳',
          options: ['ແມ່', 'ພໍ່', 'ລູກ', 'ປູ່'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຖ້າປະໂຫຍກເວົ້າວ່າ "ໝາໜ້າຮັກນອນຫຼັບຢູ່ໃຕ້ໂຕະ", ໝານອນຢູ່ໃສ? 🐶',
          options: ['ໃຕ້ໂຕະ', 'ເທິງໂຕະ', 'ເທິງຕຽງ', 'ນອກເຮືອນ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ແຊບຫຼາຍ" ໝາຍເຖິງຫຍັງ? 🌟',
          options: ['ລົດຊາດດີຫຼາຍ', 'ບໍ່ດີ', 'ເຜັດຫຼາຍ', 'ເຄັມຫຼາຍ'],
          correctIndex: 0,
        ),
      ];
    } else if (title.contains('ການບວກເລກສອງຫຼັກ')) {
      questions = [
        QuizQuestion(
          questionText: '15 + 16 ເທົ່າກັບເທົ່າໃດນໍ້? 📈',
          options: ['30', '31', '32', '33'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: '28 + 14 ເທົ່າກັບເທົ່າໃດນໍ້? ✏️',
          options: ['40', '41', '42', '43'],
          correctIndex: 2,
        ),
        QuizQuestion(
          questionText: '39 + 5 ເທົ່າກັບເທົ່າໃດນໍ້? 💎',
          options: ['44', '45', '46', '47'],
          correctIndex: 0,
        ),
      ];
    } else if (title.contains('ຮູບເລຂາຄະນິດສາມມິຕິ')) {
      questions = [
        QuizQuestion(
          questionText: 'ຮູບໃດຕໍ່ໄປນີ້ແມ່ນຮູບກ້ອນສາກ? 📦',
          options: ['ຮູບໜ່ວຍມົນ', 'ຮູບກ່ອງສາກ', 'ຮູບຈວຍ', 'ຮູບທໍ່ກົມ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ໝາກບານ ⚽ ມີຮູບຮ່າງຄືຮູບເລຂາຄະນິດໃດ?',
          options: ['ຮູບໜ່ວຍມົນ', 'ຮູບກ້ອນສາກ', 'ຮູບທໍ່ກົມ', 'ຮູບຈວຍ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ປ໋ອງນ້ຳດື່ມ 🥤 ມີຮູບຮ່າງຄືຮູບເລຂາຄະນິດໃດ?',
          options: ['ຮູບທໍ່ກົມ', 'ຮູບໜ່ວຍມົນ', 'ຮູບກ້ອນສາກ', 'ຮູບຈວຍ'],
          correctIndex: 0,
        ),
      ];
    } else if (title.contains('ໂຈດອ່ານ 1') || title.contains('ອັກສອນກາງ ກ ຈ')) {
      questions = [
        QuizQuestion(questionText: 'ອັກສອນກາງທັງໝົດ ມີຈັກຕົວ? 📚', options: ['5 ຕົວ', '7 ຕົວ', '9 ຕົວ', '6 ຕົວ'], correctIndex: 1),
        QuizQuestion(questionText: 'ຕົວໃດ ເປັນ ອັກສອນກາງ? 🌟', options: ['ຄ', 'ງ', 'ກ', 'ສ'], correctIndex: 2),
        QuizQuestion(questionText: 'ກ ຈ ດ ຕ ບ ປ ອ ຢູ່ໃນໝວດໃດ? 🔑', options: ['ໝວດຕໍ່າ', 'ໝວດກາງ', 'ໝວດສູງ', 'ໝວດພິເສດ'], correctIndex: 1),
        QuizQuestion(questionText: 'ຕົວ ຕ ຢູ່ໃນໝວດໃດ? ✍️', options: ['ໝວດຕໍ່າ', 'ໝວດສູງ', 'ໝວດກາງ', 'ໝວດພິເສດ'], correctIndex: 2),
        QuizQuestion(questionText: 'ຕົວໃດ ບໍ່ແມ່ນ ອັກສອນກາງ? 🤔', options: ['ດ', 'ຕ', 'ສ', 'ອ'], correctIndex: 2),
      ];
    } else if (title.contains('ໂຈດອ່ານ 2') || title.contains('ອັກສອນສູງ ຂ ສ')) {
      questions = [
        QuizQuestion(questionText: 'ອັກສອນສູງທັງໝົດ ມີຈັກຕົວ? 📚', options: ['3 ຕົວ', '4 ຕົວ', '5 ຕົວ', '6 ຕົວ'], correctIndex: 2),
        QuizQuestion(questionText: 'ຕົວໃດ ເປັນ ອັກສອນສູງ? 🌟', options: ['ຄ', 'ຂ', 'ກ', 'ຊ'], correctIndex: 1),
        QuizQuestion(questionText: 'ຂ ສ ຖ ຝ ຫ ຢູ່ໃນໝວດໃດ? 🔑', options: ['ໝວດຕໍ່າ', 'ໝວດກາງ', 'ໝວດສູງ', 'ໝວດພິເສດ'], correctIndex: 2),
        QuizQuestion(questionText: 'ຕົວໃດ ເປັນ ອັກສອນສູງ? ✍️', options: ['ທ', 'ໜ', 'ຝ', 'ຟ'], correctIndex: 2),
        QuizQuestion(questionText: 'ອັກສອນ ຫ ຢູ່ໃນໝວດໃດ? 🌟', options: ['ໝວດຕໍ່າ', 'ໝວດກາງ', 'ໝວດສູງ', 'ໝວດພິເສດ'], correctIndex: 2),
      ];
    } else if (title.contains('ໂຈດອ່ານ 3') || title.contains('ອັກສອນຕໍ່າ ຄ ງ ຊ')) {
      questions = [
        QuizQuestion(questionText: 'ຕົວໃດ ເປັນ ອັກສອນຕໍ່າ? 🌟', options: ['ກ', 'ຄ', 'ຂ', 'ຈ'], correctIndex: 1),
        QuizQuestion(questionText: 'ຄ ງ ຊ ຍ ທ ນ ຢູ່ໃນໝວດໃດ? 📖', options: ['ໝວດກາງ', 'ໝວດສູງ', 'ໝວດຕໍ່າ', 'ໝວດພິເສດ'], correctIndex: 2),
        QuizQuestion(questionText: 'ຕົວ ງ + ູ ໄດ້ຄຳ...? 🐍', options: ['ງູ', 'ຄູ', 'ນູ', 'ຊູ'], correctIndex: 0),
        QuizQuestion(questionText: 'ຕົວໃດ ເປັນ ອັກສອນຕໍ່າ? ✍️', options: ['ດ', 'ຖ', 'ຍ', 'ຕ'], correctIndex: 2),
        QuizQuestion(questionText: 'ຕົວ ທ ຢູ່ໃນໝວດໃດ? 🔑', options: ['ໝວດກາງ', 'ໝວດຕໍ່າ', 'ໝວດສູງ', 'ໝວດພິເສດ'], correctIndex: 1),
      ];
    } else if (title.contains('ໂຈດອ່ານ 4') || title.contains('ອັກສອນຕໍ່າ ຜ ພ')) {
      questions = [
        QuizQuestion(questionText: 'ຕົວ ຮ ຢູ່ໃນໝວດໃດ? 🌟', options: ['ໝວດສູງ', 'ໝວດກາງ', 'ໝວດຕໍ່າ', 'ໝວດພິເສດ'], correctIndex: 2),
        QuizQuestion(questionText: 'ຕົວໃດ ເປັນ ອັກສອນຕໍ່າ? 📚', options: ['ສ', 'ຫ', 'ຖ', 'ມ'], correctIndex: 3),
        QuizQuestion(questionText: 'ຕົວ ຜ ຢູ່ໃນໝວດໃດ? ✍️', options: ['ໝວດສູງ', 'ໝວດກາງ', 'ໝວດຕໍ່າ', 'ໝວດພິເສດ'], correctIndex: 2),
        QuizQuestion(questionText: 'ຕົວໃດ ບໍ່ແມ່ນ ອັກສອນຕໍ່າ? 🤔', options: ['ລ', 'ວ', 'ສ', 'ຟ'], correctIndex: 2),
        QuizQuestion(questionText: 'ຄຳ ຮຽນ 📖 ໃຊ້ອັກສອນໝວດໃດ?', options: ['ຮ (ໝວດຕໍ່າ)', 'ຫ (ໝວດສູງ)', 'ຮ (ໝວດສູງ)', 'ຫ (ໝວດຕໍ່າ)'], correctIndex: 0),
      ];
    } else if (title.contains('ໂຈດອ່ານ 5') || title.contains('ອັກສອນປະສົມ ຫງ')) {
      questions = [
        QuizQuestion(questionText: 'ໝາ 🐶 ໃຊ້ອັກສອນປະສົມໃດ?', options: ['ຫງ', 'ຫຍ', 'ໝ (ຫ+ມ)', 'ໜ (ຫ+ນ)'], correctIndex: 2),
        QuizQuestion(questionText: 'ອັກສອນ ໜ ປະກອບດ້ວຍ...? 🌟', options: ['ຫ+ງ', 'ຫ+ຍ', 'ຫ+ນ', 'ຫ+ລ'], correctIndex: 2),
        QuizQuestion(questionText: 'ຫຼານ 👦 ໃຊ້ອັກສອນປະສົມໃດ?', options: ['ຫງ', 'ຫຼ', 'ຫຍ', 'ຫວ'], correctIndex: 1),
        QuizQuestion(questionText: 'ຄຳ ຫງ ອ່ານສຽງ...? ✍️', options: ['ງ ສຽງຕໍ່າ', 'ງ ສຽງສູງ', 'ຫ ສຽງຕໍ່າ', 'ຫ ສຽງກາງ'], correctIndex: 1),
        QuizQuestion(questionText: 'ຫວານ 🍯 ໃຊ້ອັກສອນປະສົມໃດ?', options: ['ຫງ', 'ຫຍ', 'ໜ', 'ຫວ'], correctIndex: 3),
      ];
    } else if (title.contains('ໂຈດອ່ານ 6') || title.contains('ສະຫຼະສຽງສັ້ນ')) {
      questions = [
        QuizQuestion(questionText: 'xະ + ກ ໄດ້ຄຳ...? ✍️', options: ['ກາ', 'ກະ', 'ກິ', 'ກຶ'], correctIndex: 1),
        QuizQuestion(questionText: 'ສະຫຼະ xິ ອອກສຽງ...? 🌟', options: ['ອາ ສັ້ນ', 'ອິ ສັ້ນ', 'ອຶ ສັ້ນ', 'ອຸ ສັ້ນ'], correctIndex: 1),
        QuizQuestion(questionText: 'ຄຳ ຈຸ 🖊 ໃຊ້ສະຫຼະໃດ?', options: ['xະ', 'xິ', 'xຶ', 'xຸ'], correctIndex: 3),
        QuizQuestion(questionText: 'xຶ + ສ ໄດ້ຄຳ...? 🐯', options: ['ສິ', 'ສຸ', 'ສຶ', 'ສາ'], correctIndex: 2),
        QuizQuestion(questionText: 'ສະຫຼະໃດ ອອກສຽງ ອຶ ສັ້ນ? 🔑', options: ['xະ', 'xິ', 'xຶ', 'xຸ'], correctIndex: 2),
      ];
    } else if (title.contains('ໂຈດອ່ານ 7') || title.contains('ສະຫຼະສຽງຍາວ')) {
      questions = [
        QuizQuestion(questionText: 'ກາ 🐦 ໃຊ້ສະຫຼະໃດ?', options: ['xີ', 'xາ', 'xື', 'xູ'], correctIndex: 1),
        QuizQuestion(questionText: 'xີ + ດ ໄດ້ຄຳ...? 🌟', options: ['ດາ', 'ດີ', 'ດື', 'ດູ'], correctIndex: 1),
        QuizQuestion(questionText: 'ມື ✋ ໃຊ້ສະຫຼະໃດ?', options: ['xາ', 'xີ', 'xື', 'xູ'], correctIndex: 2),
        QuizQuestion(questionText: 'xູ + ຈ ໄດ້ຄຳ...? 🔑', options: ['ຈາ', 'ຈີ', 'ຈື', 'ຈູ'], correctIndex: 3),
        QuizQuestion(questionText: 'ສະຫຼະ xາ ໝາຍເຖິງ...? 📖', options: ['ອາ ສັ້ນ', 'ອາ ຍາວ', 'ອີ ຍາວ', 'ອຶ ຍາວ'], correctIndex: 1),
      ];
    } else if (title.contains('ໂຈດອ່ານ 8') || title.contains('ສະຫຼະ ເx ແx')) {
      questions = [
        QuizQuestion(questionText: 'ແx + ກ ໄດ້ຄຳ...? 🌟', options: ['ເກ', 'ແກ', 'ໂກ', 'ກໍ'], correctIndex: 1),
        QuizQuestion(questionText: 'ໂນ 🐂 ໃຊ້ສະຫຼະໃດ?', options: ['ເx', 'ແx', 'ໂx', 'xໍ'], correctIndex: 2),
        QuizQuestion(questionText: 'xໍ + ປ ໄດ້ຄຳ...? 💎', options: ['ເປ', 'ແປ', 'ໂປ', 'ປໍ'], correctIndex: 3),
        QuizQuestion(questionText: 'ແທ ໃຊ້ສະຫຼະໃດ? 🌟', options: ['ເx', 'ແx', 'ໂx', 'xໍ'], correctIndex: 1),
        QuizQuestion(questionText: 'ເດ ໃຊ້ສະຫຼະໃດ? 📖', options: ['ແx', 'ເx', 'ໂx', 'xໍ'], correctIndex: 1),
      ];
    } else if (title.contains('ບົດທີ 1: ການປຽບທຽບຈຳນວນ')) {
      questions = [
        QuizQuestion(
          questionText: 'ໝາກປູມເປົ້າ 🎈 ມີ 5 ໜ່ວຍ, ສໍ້ດຳ ✏️ ມີ 3 ກ້ານ. ສິ່ງໃດມີຈຳນວນຫຼາຍກວ່າ?',
          options: ['ໝາກປູມເປົ້າ 🎈', 'ສໍ້ດຳ ✏️', 'ເທົ່າກັນ', 'ບໍ່ມີຂໍ້ຖືກ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ປຽບທຽບໝາກກ້ວຍ 🍌 2 ໜ່ວຍ ແລະ ໝາກອັບເປີ້ນ 🍎 2 ໜ່ວຍ. ຈຳນວນທັງສອງເປັນແນວໃດ?',
          options: ['ຫຼາຍກວ່າ', 'ໜ້ອຍກວ່າ', 'ເທົ່າກັນ ⚖️', 'ຕ່າງກັນ'],
          correctIndex: 2,
        ),
        QuizQuestion(
          questionText: 'ປຽບທຽບຊ້າງ 🐘 ຕົວໃຫຍ່ ແລະ ແມວ 🐱 ຕົວນ້ອຍ. ສັດໂຕໃດໃຫຍ່ກວ່າ?',
          options: ['ແມວ 🐱', 'ຊ້າງ 🐘', 'ເທົ່າກັນ', 'ນ້ອຍເທົ່າກັນ'],
          correctIndex: 1,
        ),
      ];
    } else if (title.contains('ບົດທີ 2: ຈຳນວນແຕ່ 1 ເຖິງ 10 ແລະ 0')) {
      questions = [
        QuizQuestion(
          questionText: 'ນັບຈຳນວນໝາກໄມ້: 🍎 🍎 🍎 ມີຈັກໜ່ວຍ?',
          options: ['2 ໜ່ວຍ', '3 ໜ່ວຍ 🍎', '4 ໜ່ວຍ', '5 ໜ່ວຍ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຫາກບໍ່ມີຫຍັງເລີຍ ຢູ່ໃນກ່ອງ, ເຮົາຈະຂຽນແທນດ້ວຍຕົວເລກໃດ?',
          options: ['1', '2', '0 📦', '3'],
          correctIndex: 2,
        ),
        QuizQuestion(
          questionText: 'ຕົວເລກໃດແມ່ນ \'ເລກເຈັດ\' ທີ່ຖືກຕ້ອງ?',
          options: ['5', '6', '7 🌟', '8'],
          correctIndex: 2,
        ),
      ];
    } else if (title.contains('ບົດທີ 3: ລຳດັບທີ')) {
      questions = [
        QuizQuestion(
          questionText: '🐱 (ທີ 1) -> 🐶 (ທີ 2) -> 🐰 (ທີ 3). 🐶 ຢູ່ລຳດັບທີເທົ່າໃດ?',
          options: ['ລຳດັບທີ 1', 'ລຳດັບທີ 2 🐶', 'ລຳດັບທີ 3', 'ລຳດັບສຸດທ້າຍ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ສິ່ງໃດຢູ່ \'ທາງໜ້າ\' ໝູ່ ລະຫວ່າງ: 🚗 🚲 🚶?',
          options: ['ລົດຖີບ 🚲', 'ລົດຍົນ 🚗', 'ຄົນຍ່າງ 🚶', 'ຢູ່ກາງ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ສິ່ງໃດຢູ່ \'ທາງຫຼັງ\' ໝູ່ ລະຫວ່າງ: 🚗 🚲 🚶?',
          options: ['ລົດຍົນ 🚗', 'ລົດຖີບ 🚲', 'ຄົນຍ່າງ 🚶', 'ຢູ່ໜ້າ'],
          correctIndex: 2,
        ),
      ];
    } else if (title.contains('ບົດທີ 4: ການແບ່ງຈຳນວນອອກເປັນສອງສ່ວນ')) {
      questions = [
        QuizQuestion(
          questionText: 'ຈຳນວນ 5 ແບ່ງອອກເປັນ 2 ສ່ວນ. ຫາກສ່ວນໜຶ່ງແມ່ນ 3, ອີກສ່ວນໜຶ່ງແມ່ນເທົ່າໃດ?',
          options: ['1', '2 ✌️', '3', '4'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຈຳນວນ 6 ສາມາດແບ່ງເປັນ 4 ແລະ ເທົ່າໃດ?',
          options: ['1', '2 ✌️', '3', '4'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຈຳນວນ 10 ສາມາດແບ່ງເປັນ 5 ແລະ ເທົ່າໃດ?',
          options: ['4', '5 🖐️', '6', '7'],
          correctIndex: 1,
        ),
      ];
    } else if (title.contains('ບົດທີ 5: ການບວກ')) {
      questions = [
        QuizQuestion(
          questionText: '2 + 3 ເທົ່າກັບເທົ່າໃດ? 🍎',
          options: ['4', '5 🍎', '6', '7'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: '4 + 4 ເທົ່າກັບເທົ່າໃດ? 🧮',
          options: ['6', '7', '8 🧮', '9'],
          correctIndex: 2,
        ),
        QuizQuestion(
          questionText: '5 + 0 ເທົ່າກັບເທົ່າໃດ? 🌟',
          options: ['0', '5 🌟', '10', '6'],
          correctIndex: 1,
        ),
      ];
    } else if (title.contains('ບົດທີ 6: ການລົບ')) {
      questions = [
        QuizQuestion(
          questionText: '5 - 2 ເທົ່າກັບເທົ່າໃດ? 🍎',
          options: ['2', '3 🍎', '4', '1'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: '8 - 4 ເທົ່າກັບເທົ່າໃດ? 🧮',
          options: ['2', '3', '4 🧮', '5'],
          correctIndex: 2,
        ),
        QuizQuestion(
          questionText: '7 - 7 ເທົ່າກັບເທົ່າໃດ? 🌀',
          options: ['0 🌀', '1', '7', '14'],
          correctIndex: 0,
        ),
      ];
    } else if (title.contains('ບົດທີ 7: ຈຳນວນທີ່ຫຼາຍກວ່າ 10')) {
      questions = [
        QuizQuestion(
          questionText: '1 ຫຼັກຫົວສິບ ກັບ 5 ຫຼັກຫົວໜ່ວຍ ແມ່ນຈຳນວນໃດ?',
          options: ['10', '15 🌟', '51', '20'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ນັບຕໍ່ຈາກ 14 ໄປອີກ 1 ຈະໄດ້ຈຳນວນໃດ?',
          options: ['13', '15 🌟', '16', '12'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ເລກ 18 ຂຽນແຍກເປັນຫຼັກຫົວສິບ ແລະ ຫຼັກຫົວໜ່ວຍໄດ້ແນວໃດ?',
          options: ['10 + 8 🧮', '1 + 8', '10 + 80', '18 + 0'],
          correctIndex: 0,
        ),
      ];
    } else if (title.contains('ບົດທີ 8: ການບວກ (ຕໍ່)')) {
      questions = [
        QuizQuestion(
          questionText: '9 + 3 ເທົ່າກັບເທົ່າໃດ? 🍎',
          options: ['11', '12 🍎', '13', '14'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: '8 + 6 ເທົ່າກັບເທົ່າໃດ? 🧮',
          options: ['13', '14 🧮', '15', '16'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: '10 + 7 ເທົ່າກັບເທົ່າໃດ? 🌟',
          options: ['17 🌟', '70', '107', '16'],
          correctIndex: 0,
        ),
      ];
    } else if (title.contains('ບົດທີ 9: ການລົບ (ຕໍ່)')) {
      questions = [
        QuizQuestion(
          questionText: '12 - 3 ເທົ່າກັບເທົ່າໃດ? 🍎',
          options: ['8', '9 🍎', '10', '11'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: '15 - 7 ເທົ່າກັບເທົ່າໃດ? 🧮',
          options: ['7', '8 🧮', '9', '6'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: '18 - 10 ເທົ່າກັບເທົ່າໃດ? 🌟',
          options: ['8 🌟', '10', '18', '0'],
          correctIndex: 0,
        ),
      ];
    } else if (title.contains('ບົດທີ 10: ການຄິດໄລ່ຂອງ 3 ຈຳນວນ')) {
      questions = [
        QuizQuestion(
          questionText: '3 + 2 + 4 ເທົ່າກັບເທົ່າໃດ? 🍎',
          options: ['8', '9 🍎', '10', '7'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: '10 - 3 - 2 ເທົ່າກັບເທົ່າໃດ? 🧮',
          options: ['4', '5 🧮', '6', '7'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: '8 - 2 + 4 ເທົ່າກັບເທົ່າໃດ? 🌟',
          options: ['9', '10 🌟', '11', '8'],
          correctIndex: 1,
        ),
      ];
    } else if (title.contains('ບົດທີ 11: ການປຽບທຽບຄວາມຍາວ')) {
      questions = [
        QuizQuestion(
          questionText: 'ລະຫວ່າງ ໄມ້ດິ້ວ 🥢 ແລະ ສໍ້ດຳ ✏️. ຫາກໄມ້ດິ້ວຍາວກວ່າສໍ້ດຳ, ສິ່ງໃດສັ້ນກວ່າ?',
          options: ['ໄມ້ດິ້ວ 🥢', 'ສໍ້ດຳ ✏️', 'ຍາວເທົ່າກັນ', 'ບໍ່ມີຂໍ້ຖືກ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຫາກເຮົາຢາກຮູ້ວ່າໂຕເລກໃດຍາວກວ່າ, ເຮົາຄວນເຮັດແນວໃດ?',
          options: ['ເອົາສົ້ນເບື້ອງໜຶ່ງມາລຽນຊື່ກັນ 📏', 'ວາງໄກໆກັນ', 'ຄາດເດົາດ້ວຍສາຍຕາ', 'ບໍ່ມີວິທີວັດ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ສາຍເຊືອກ A ຍາວ 8 ຊມ, ສາຍເຊືອກ B ຍາວ 12 ຊມ. ເຊືອກໃດຍາວກວ່າ?',
          options: ['ເຊືອກ A', 'ເຊືອກ B 🌟', 'ຍາວເທົ່າກັນ', 'ສັ້ນເທົ່າກັນ'],
          correctIndex: 1,
        ),
      ];
    } else if (title.contains('ບົດທີ 12: ຮູບຮ່າງຂອງສິ່ງຕ່າງໆທີ່ຢູ່ອ້ອມຕົວເຮົາ')) {
      questions = [
        QuizQuestion(
          questionText: 'ກ່ອງຢາຖູແຂ້ວ 📦 ມີຮູບຮ່າງໃກ້ຄຽງກັບຮູບໃດຫຼາຍທີ່ສຸດ?',
          options: ['ຮູບຊົງກະບອກ', 'ຮູບຊົງກົມ', 'ຮູບກ່ອງສີ່ຫຼັກ 📦', 'ຮູບສາມຫຼ່ຽມ'],
          correctIndex: 2,
        ),
        QuizQuestion(
          questionText: 'ໝາກສົ້ມ 🍊 ມີຮູບຮ່າງຄ້າຍຄືກັບຮູບໃດ?',
          options: ['ຮູບຊົງກົມ 🍊', 'ຮູບຊົງກະບອກ', 'ຮູບຊົງກ້ອນ', 'ຮູບສີ່ຫຼ່ຽມ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ປ໋ອງນົມ 🥛 ມີຮູບຮ່າງຄືກັບຮູບໃດ?',
          options: ['ຮູບຊົງກົມ', 'ຮູບຊົງກະບອກ (ທໍ່ກົມ) 🥛', 'ຮູບກ່ອງ', 'ຮູບສາມຫຼ່ຽມ'],
          correctIndex: 1,
        ),
      ];
    } else if (title.contains('ບົດທີ 13: ໂມງ (ການອ່ານເວລາ)')) {
      questions = [
        QuizQuestion(
          questionText: 'ເຂັມສັ້ນຊີ້ໃສ່ເລກ 3, ເຂັມຍາວຊີ້ໃສ່ເລກ 12. ແມ່ນເວລາຈັກໂມງ?',
          options: ['12 ໂມງ', '3 ໂມງ ⏰', '6 ໂມງ', '9 ໂມງ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ໃນ 1 ວັນ ມີທັງໝົດຈັກຊົ່ວໂມງ? 📅',
          options: ['12 ຊົ່ວໂມງ', '24 ຊົ່ວໂມງ 📅', '60 ຊົ່ວໂມງ', '10 ຊົ່ວໂມງ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ເຂັມໃດໃນໂມງທີ່ໃຊ້ບອກ \'ຊົ່ວໂມງ\'?',
          options: ['Eຂັມຍາວ', 'ເຂັມສັ້ນ ⏰', 'ເຂັມວິນາທີ', 'ທຸກເຂັມ'],
          correctIndex: 1,
        ),
      ];
    } else if (title.contains('ບົດທີ 14: ການບວກ ແລະ ການລົບ (ຕໍ່)')) {
      questions = [
        QuizQuestion(
          questionText: '13 + 5 ເທົ່າກັບເທົ່າໃດ? 🍎',
          options: ['17', '18 🍎', '19', '16'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: '17 - 4 ເທົ່າກັບເທົ່າໃດ? 🧮',
          options: ['12', '13 🧮', '14', '15'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: '20 - 5 ເທົ່າກັບເທົ່າໃດ? 🌟',
          options: ['10', '15 🌟', '16', '17'],
          correctIndex: 1,
        ),
      ];
    } else if (title.contains('ບົດທີ 15: ການປຽບທຽບປະລິມານ (ຄວາມບັນຈຸ)')) {
      questions = [
        QuizQuestion(
          questionText: 'ຂວດນ້ຳໃຫຍ່ 🍼 ແລະ ຈອກນ້ຳນ້ອຍ 🥛. ພາຊະນະໃດສາມາດບັນຈຸນ້ຳໄດ້ຫຼາຍກວ່າ?',
          options: ['ຂວດນ້ຳໃຫຍ່ 🍼', 'ຈອກນ້ຳນ້ອຍ 🥛', 'ເທົ່າກັນ', 'ບໍ່ມີຂໍ້ຖືກ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຫາກເຮົາຖອກນ້ຳຈາກຈອກໃສ່ຊາມແລ້ວນ້ຳບໍ່ເຕັມຊາມ, ສິ່ງໃດໃຫຍ່ກວ່າ?',
          options: ['ຈອກ', 'ຊາມ 🥣', 'ເທົ່າກັນ', 'ບໍ່ສາມາດບອກໄດ້'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຖັງນ້ຳ A ໃສ່ນ້ຳໄດ້ 5 ລິດ, ຖັງນ້ຳ B ໃສ່ນ້ຳໄດ້ 3 ລິດ. ຖັງໃດມີຄວາມບັນຈຸຫຼາຍກວ່າ?',
          options: ['ຖັງ A 🌟', 'ຖັງ B', 'ເທົ່າກັນ', 'ສັ້ນກວ່າ'],
          correctIndex: 0,
        ),
      ];
    } else if (title.contains('ບົດທີ 16: ຮູບຮ່າງ ແລະ ການຈັດລຽງ')) {
      questions = [
        QuizQuestion(
          questionText: 'ຮູບແບບ: 🔴 🔵 🔴 🔵 🔴 ... ຮູບຕໍ່ໄປຄວນເປັນສີຫຍັງ?',
          options: ['ສີແດງ 🔴', 'ສີຟ້າ 🔵', 'ສີຂຽວ', 'ສີເຫຼືອງ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຮູບແບບ: 🔺 🟩 🔺 🟩 ... ຮູບຕໍ່ໄປຄວນເປັນຮູບໃດ?',
          options: ['ຮູບສາມຫຼ່ຽມ 🔺', 'ຮູບສີ່ຫຼ່ຽມ 🟩', 'ຮູບວົງມົນ', 'ຮູບຫ້າຫຼ່ຽມ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຮູບແບບ: 1, 2, 1, 2, 1, ... ຕົວເລກຕໍ່ໄປແມ່ນເລກໃດ?',
          options: ['1', '2 🌟', '3', '0'],
          correctIndex: 1,
        ),
      ];
    } else if (title.contains('ບົດທີ 17: ຈຳນວນທີ່ຫຼາຍກວ່າ 20')) {
      questions = [
        QuizQuestion(
          questionText: '2 ຫຼັກຫົວສິບ ກັບ 4 ຫຼັກຫົວໜ່ວຍ ແມ່ນຈຳນວນໃດ?',
          options: ['20', '24 🌟', '42', '204'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ເລກ 35 ຂຽນແຍກເປັນຫຼັກຫົວສິບ ແລະ ຫຼັກຫົວໜ່ວຍໄດ້ແນວໃດ?',
          options: ['30 + 5 🧮', '3 + 5', '30 + 50', '35 + 0'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ນັບເພີ່ມເທື່ອລະ 10: 10, 20, 30, ... ຈຳນວນຕໍ່ໄປແມ່ນຫຍັງ?',
          options: ['35', '40 🌟', '50', '100'],
          correctIndex: 1,
        ),
      ];
    } else if (title.contains('ບົດທີ 18: ເລກລາວ')) {
      questions = [
        QuizQuestion(
          questionText: 'ຕົວເລກລາວ \'໕\' ກົງກັບເລກອາຣັບໃດ?',
          options: ['3', '4', '5 🌟', '6'],
          correctIndex: 2,
        ),
        QuizQuestion(
          questionText: 'ຕົວເລກລາວ \'໑໐\' ແມ່ນເລກໃດ?',
          options: ['1', '10 🌟', '5', '0'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຕົວເລກລາວ \'໓\' ກົງກັບເລກອາຣັບໃດ?',
          options: ['2', '3 🌟', '4', '5'],
          correctIndex: 1,
        ),
      ];
    } else if (title.contains('ໂຈດອ່ານ 9') || title.contains('ສະຫຼະພິເສດ')) {
      questions = [
        QuizQuestion(questionText: 'ລຳ 💃 ໃຊ້ສະຫຼະໃດ?', options: ['xໄ', 'xໃ', 'xຳ', 'xົ'], correctIndex: 2),
        QuizQuestion(questionText: 'ສະຫຼະ xໄ ແລະ xໃ ອອກສຽງ...? 🌟', options: ['... ສຽງດຽວກັນ', '... ສຽງຍາວ', '... ສຽງສັ້ນ', 'ຕ່າງກັນ'], correctIndex: 0),
        QuizQuestion(questionText: 'ມົດ 🐜 ໃຊ້ສະຫຼະໃດ?', options: ['xຳ', 'xົ', 'xົວ', 'ເxຍ'], correctIndex: 1),
        QuizQuestion(questionText: 'ເຮືອ ⛵ ໃຊ້ສະຫຼະໃດ?', options: ['ເxຍ', 'ເxືອ', 'xົວ', 'xໃ'], correctIndex: 1),
        QuizQuestion(questionText: 'ເຢຍ ໃຊ້ສະຫຼະໃດ? 🌟', options: ['... ໃຊ້ສະຫຼະ ເxຍ', '... ໃຊ້ສະຫຼະ ເxືອ', '... ໃຊ້ສະຫຼະ xໄ', '... ໃຊ້ສະຫຼະ xຳ'], correctIndex: 0),
      ];
    } else {
      // Fallback questions if any custom lesson is added
      questions = [
        QuizQuestion(
          questionText: 'ພະຍັນຊະນະຕົວໃດແມ່ນຕົວ "ກ"? 🌟',
          options: ['ກ', 'ຂ', 'ຄ', 'ງ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຮູບໝາໜ້າຮັກ 🐶 ອອກສຽງພະຍັນຊະນະຕົວໃດ?',
          options: ['ມ', 'ໝ', 'ກ', 'ສ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຄຳສັບໃດອອກສຽງສະຫຼະ "າ"? 🍉',
          options: ['ກິ', 'ກຸ', 'ກາ', 'ເກ'],
          correctIndex: 2,
        ),
      ];
    }
  }

  Future<void> _playCorrectSound() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource('https://raw.githubusercontent.com/piyushiitk24/EduLadder/master/audio/correct.mp3'));
    } catch (e) {
      debugPrint('Error playing correct sound: $e');
    }
  }

  Future<void> _playIncorrectSound() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource('https://raw.githubusercontent.com/piyushiitk24/EduLadder/master/audio/incorrect.mp3'));
    } catch (e) {
      debugPrint('Error playing incorrect sound: $e');
    }
  }

  void _checkAnswer(int index) {
    if (showFeedback) return; // Already answered
    if (_failedOptionIndices.contains(index)) return; // Already tapped incorrect option

    setState(() {
      final isCorrect = index == questions[currentQuestionIndex].correctIndex;
      selectedOptionIndex = index;
      showFeedback = true;

      if (isCorrect) {
        isAnswerCorrect = true;
        if (!_hadMistake) {
          score++;
        }
        _playCorrectSound();
      } else {
        isAnswerCorrect = false;
        _hadMistake = true;
        _failedOptionIndices.add(index);
        _playIncorrectSound();
      }
    });
  }

  void _nextQuestion() async {
    try {
      await _flutterTts.stop();
    } catch (_) {}
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        selectedOptionIndex = -1;
        showFeedback = false;
        isAnswerCorrect = false;
        _failedOptionIndices.clear();
        _hadMistake = false;
        _isSpeaking = false;
        _isMicRecording = false;
        _hasReadCurrent = false;
      });
    } else {
      // Save progress to SQLite
      await DatabaseHelper.instance.saveProgress(
        currentUserId,
        lesson!.id!,
        isReadingMode ? lesson!.totalStars : score,
      );

      if (!mounted) return;
      // Show Completion Dialog
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'ຫຼານຮຽນເກັ່ງຫຼາຍ! 🎉',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ).animate().scale(duration: 800.ms, curve: Curves.bounceOut),
              const SizedBox(height: 16),
              const CircleAvatar(
                radius: 40,
                backgroundColor: AppTheme.primaryYellow,
                child: Icon(Icons.stars_rounded, size: 60, color: Colors.white),
              ).animate().scale(delay: 200.ms),
              const SizedBox(height: 16),
              Text(
                isReadingMode
                    ? 'ຫຼານຝຶກອ່ານໄດ້ເກັ່ງຫຼາຍ! 📖'
                    : (lesson?.subject == 'ຄະນິດສາດ'
                        ? 'ຫຼານແກ້ເລກໄດ້ຄະແນນເຕັມ! 🌟'
                        : 'ຫຼານຕອບຄຳຖາມໄດ້ຄະແນນເຕັມ! 🌟'),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              // Stars earned
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  isReadingMode ? lesson!.totalStars : score,
                  (index) => const Icon(
                    Icons.star_rounded,
                    color: Color(0xFFF59E0B),
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF38B264),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop(); // Dismiss Dialog
                  context.pop(); // Go back to lessons list
                },
                child: const Text(
                  'ກັບຄືນຫາບົດຮຽນ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentQuestion = questions[currentQuestionIndex];
    final progressRatio = (currentQuestionIndex + 1) / questions.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text(
          lesson!.title.split(':').first, // Shows e.g. "ບົດທີ 1"
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: AppTheme.textColor,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppTheme.textColor),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress Bar
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progressRatio,
                        minHeight: 12,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF3E8EF7),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    '${currentQuestionIndex + 1}/${questions.length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Question block card
              Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 28,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Smart TTS Speaker Button – adapts to Lao availability
                        GestureDetector(
                          onTap: _isCheckingLao
                              ? null
                              : () => _speakQuestion(currentQuestion.questionText),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: _isCheckingLao
                                  ? Colors.grey.shade100
                                  : !_isLaoAvailable
                                      ? const Color(0xFFFFF8E1)
                                      : _isSpeaking
                                          ? const Color(0xFFE8F5E9)
                                          : const Color(0xFFE3F2FD),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _isCheckingLao
                                    ? Colors.grey.shade300
                                    : !_isLaoAvailable
                                        ? const Color(0xFFFFCA28)
                                        : _isSpeaking
                                            ? const Color(0xFF81C784)
                                            : const Color(0xFF90CAF9),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_isCheckingLao) ...[
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.grey),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'ກຳລັງກວດສອບສຽງ...',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ] else if (!_isLaoAvailable) ...[
                                  const Icon(
                                    Icons.download_rounded,
                                    color: Color(0xFFF57F17),
                                    size: 22,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'ດາວໂຫຼດສຽງລາວ 🔔',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFF57F17),
                                    ),
                                  ),
                                ] else ...[
                                  Icon(
                                    _isSpeaking
                                        ? Icons.volume_up_rounded
                                        : Icons.volume_mute_rounded,
                                    color: _isSpeaking
                                        ? const Color(0xFF2E7D32)
                                        : const Color(0xFF1E88E5),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _isSpeaking
                                        ? 'ກຳລັງເວົ້າ... ເວົ້າຕາມເດີ້ 🗣️'
                                        : 'ຟັງສຽງເດັກນ້ອຍແລ້ວເວົ້າຕາມ 🔊',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: _isSpeaking
                                          ? const Color(0xFF2E7D32)
                                          : const Color(0xFF1E88E5),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ).animate(target: (_isLaoAvailable && _isSpeaking) ? 1 : 0)
                         .shimmer(duration: 1.seconds, curve: Curves.easeInOut)
                         .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05)),
                        const SizedBox(height: 18),
                        Text(
                          currentQuestion.questionText,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isReadingMode ? 100 : 22,
                            fontWeight: FontWeight.bold,
                            color: isReadingMode ? AppTheme.primaryPink : AppTheme.textColor,
                            height: 1.1,
                          ),
                        ),
                        if (isReadingMode && currentQuestion.readingGuide != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            currentQuestion.readingGuide!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                  .animate(key: ValueKey(currentQuestionIndex))
                  .fade()
                  .scale(curve: Curves.easeOutBack),
              const SizedBox(height: 20),

              if (isReadingMode) ...[
                // Reading Mode Body: Microphone practice and next navigation
                Expanded(
                  child: Column(
                    children: [
                      // Middle scrollable practice area
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 10),
                              // Animated Mic Button
                              GestureDetector(
                                onTap: () {
                                  if (_isMicRecording) {
                                    _stopSpeechListeningAndVerify();
                                  } else {
                                    _startSpeechListening();
                                  }
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _isMicRecording
                                        ? const Color(0xFFE0F7FA) // Soft cyan when actively listening
                                        : _hasReadCurrent
                                            ? const Color(0xFFE8F5E9) // Soft green when correct
                                            : _showIncorrectGuide
                                                ? const Color(0xFFFFEBEE) // Soft red when incorrect
                                                : const Color(0xFFE3F2FD), // Soft blue when idle
                                    border: Border.all(
                                      color: _isMicRecording
                                          ? const Color(0xFF00ACC1)
                                          : _hasReadCurrent
                                              ? const Color(0xFF81C784)
                                              : _showIncorrectGuide
                                                  ? const Color(0xFFE57373)
                                                  : const Color(0xFF90CAF9),
                                      width: 4,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (_isMicRecording
                                            ? const Color(0xFF00ACC1)
                                            : _hasReadCurrent
                                                ? const Color(0xFF66BB6A)
                                                : _showIncorrectGuide
                                                    ? const Color(0xFFEF5350)
                                                    : const Color(0xFF42A5F5)).withValues(alpha: 0.3),
                                        blurRadius: 20,
                                        spreadRadius: _isMicRecording ? 8 : 2,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    _isMicRecording
                                        ? Icons.mic_rounded
                                        : _hasReadCurrent
                                            ? Icons.check_circle_rounded
                                            : _showIncorrectGuide
                                                ? Icons.mic_rounded
                                                : Icons.mic_none_rounded,
                                    size: 56,
                                    color: _isMicRecording
                                        ? const Color(0xFF00838F)
                                        : _hasReadCurrent
                                            ? const Color(0xFF2E7D32)
                                            : _showIncorrectGuide
                                                ? const Color(0xFFC62828)
                                                : const Color(0xFF1E88E5),
                                  ),
                                ),
                              ).animate(target: _isMicRecording ? 1 : 0)
                               .scale(begin: const Offset(1, 1), end: const Offset(1.15, 1.15), duration: 500.ms, curve: Curves.easeInOut)
                               .then()
                               .shake(duration: 500.ms),
                              const SizedBox(height: 16),
                              Text(
                                _isMicRecording
                                    ? 'ຫຼານກຳລັງອ່ານ... 🎙️ ເວົ້າເລີຍເດີ້!'
                                    : _hasReadCurrent
                                        ? 'ຫຼານອ່ານເກັ່ງຫຼາຍ! 🏆 ສຸດຍອດເລີຍ'
                                        : _showIncorrectGuide
                                            ? 'ຫຼານອ່ານເກືອບຖືກແລ້ວ! ລອງອ່ານຄືນໃໝ່ເດີ້ 🎙️'
                                            : 'ກົດປຸ່ມແລ້ວຝຶກອ່ານອອກສຽງ 🎙️',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: _isMicRecording
                                      ? const Color(0xFF00838F)
                                      : _hasReadCurrent
                                          ? const Color(0xFF2E7D32)
                                          : _showIncorrectGuide
                                              ? const Color(0xFFC62828)
                                              : const Color(0xFF1E88E5),
                                ),
                              ),

                              // Animated sound level visualizer when recording
                              if (_isMicRecording) ...[
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(5, (index) {
                                    return Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                      width: 6,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFC62828),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                                     .scaleY(
                                       begin: 0.3,
                                       end: 1.5,
                                       duration: Duration(milliseconds: 200 + (index * 80)),
                                       curve: Curves.easeInOut,
                                     );
                                  }),
                                ),
                              ],

                              // Parent/Self Verification panel (in case engine not available or noisy environment)
                              if (_showSelfVerification) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF9C4), // Soft yellow
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFFBC02D), width: 1.5),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'ພໍ່ແມ່ ຫຼື ຫຼານໄດ້ອ່ານອອກສຽງ "${currentQuestion.questionText}" ດັງໆແລ້ວແມ່ນບໍ່? 🗣️',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF5D4037),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                              backgroundColor: const Color(0xFFFF8A65), // soft orange
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _hasReadCurrent = false;
                                                _showSelfVerification = false;
                                                _showIncorrectGuide = true;
                                              });
                                              _playIncorrectSound();
                                              _speakIncorrectPrompt(currentQuestion.questionText);
                                            },
                                            child: const Text('ຍັງບໍ່ໄດ້ອ່ານ/ອ່ານຜິດ ❌', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                              backgroundColor: const Color(0xFF4CAF50), // green
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _hasReadCurrent = true;
                                                _showSelfVerification = false;
                                                _showIncorrectGuide = false;
                                              });
                                              _playCorrectSound();
                                            },
                                            child: const Text('ອ່ານຖືກຕ້ອງແລ້ວ! 💚', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ).animate().fade().scale(),
                              ],

                              // Incorrect guide warning and background noise override
                              if (_showIncorrectGuide && !_showSelfVerification) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFEBEE), // soft red
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFEF5350), width: 1.5),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        'ຫຼານລອງອ່ານອອກສຽງຄືນໃໝ່ໃຫ້ດັງ ແລະ ຊັດເຈນອີກເທື່ອໜຶ່ງເດີ້! 🎙️',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red.shade900,
                                        ),
                                      ),
                                      if (_recognizedWords.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'ສຽງທີ່ໄດ້ຍິນ: "$_recognizedWords"',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontStyle: FontStyle.italic,
                                            color: Colors.red.shade700,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 6),
                                      TextButton.icon(
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          backgroundColor: Colors.white.withValues(alpha: 0.8),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        icon: const Icon(Icons.volume_off_rounded, size: 14, color: Color(0xFFEF5350)),
                                        label: const Text(
                                          'ກົດບ່ອນນີ້ຫາກຢູ່ບ່ອນມີສຽງລົບກວນ 🔊',
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFC62828)),
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _showSelfVerification = true;
                                            _showIncorrectGuide = false;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ).animate().shake(duration: 400.ms),
                              ],
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Navigation Done/Next Button anchored at bottom
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _hasReadCurrent ? const Color(0xFF38B264) : Colors.grey.shade400,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            elevation: _hasReadCurrent ? 4 : 1,
                          ),
                          onPressed: () {
                            if (!_hasReadCurrent) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.mic_rounded, color: Colors.white),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _recognizedWords.isEmpty
                                              ? 'ຫຼານຕ້ອງກົດປຸ່ມໄມ 🎙️ ແລະ ຝຶກອ່ານອອກສຽງກ່ອນເດີ້!'
                                              : 'ຫຼານອ່ານຍັງບໍ່ຖືກຕ້ອງເທື່ອ 🎙️ ລອງກົດປຸ່ມໄມແລ້ວອ່ານຄືນໃໝ່ເດີ້!',
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: const Color(0xFFE57373),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                              _speakIncorrectPrompt(currentQuestion.questionText);
                            } else {
                              _nextQuestion();
                            }
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                currentQuestionIndex < questions.length - 1
                                    ? 'ອ່ານຂໍ້ຕໍ່ໄປ'
                                    : 'ສຳເລັດ ບົດຮຽນ 🎓',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                _hasReadCurrent ? Icons.arrow_forward_rounded : Icons.lock_outline_rounded,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // MCQ Options grid of rectangular blocks
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                    children: List.generate(currentQuestion.options.length, (
                      index,
                    ) {
                      final isCorrectOption =
                          index == currentQuestion.correctIndex;
                      final isFailedOption = _failedOptionIndices.contains(index);

                      Color cardColor = Colors.white;
                      Color textColor = AppTheme.textColor;
                      BorderSide border = BorderSide(
                        color: Colors.grey.shade200,
                        width: 1.5,
                      );

                      if (isFailedOption) {
                        cardColor = const Color(0xFFFFEBEE);
                        textColor = const Color(0xFFC62828);
                        border = const BorderSide(
                          color: Color(0xFFE57373),
                          width: 2.5,
                        );
                      } else if (showFeedback && isCorrectOption) {
                        cardColor = const Color(0xFFE8F5E9);
                        textColor = const Color(0xFF2E7D32);
                        border = const BorderSide(
                          color: Color(0xFF81C784),
                          width: 2.5,
                        );
                      } else if (selectedOptionIndex == index) {
                        cardColor = const Color(0xFFE3F2FD);
                        border = const BorderSide(
                          color: Color(0xFF3E8EF7),
                          width: 2.5,
                        );
                      }

                      return StatefulBuilder(
                        builder: (context, setState) {
                          double scale = 1.0;
                          return GestureDetector(
                            onTapDown: (_) => setState(() => scale = 0.95),
                            onTapUp: (_) => setState(() => scale = 1.0),
                            onTapCancel: () => setState(() => scale = 1.0),
                            onTap: () => _checkAnswer(index),
                            child: AnimatedScale(
                              scale: scale,
                              duration: const Duration(milliseconds: 100),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.fromBorderSide(border),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.02),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    currentQuestion.options[index],
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ),

                // Feedback Banner & Navigation Controls
                if (showFeedback) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: isAnswerCorrect
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isAnswerCorrect
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          color: isAnswerCorrect
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFC62828),
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAnswerCorrect
                                    ? 'ຫຼານເກັ່ງຫຼາຍ! 🎉'
                                    : 'ພະຍາຍາມໃໝ່ເດີ້! 💪',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isAnswerCorrect
                                      ? const Color(0xFF2E7D32)
                                      : const Color(0xFFC62828),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isAnswerCorrect
                                    ? 'ຄຳຕອບຖືກຕ້ອງແລ້ວ.'
                                    : 'ບໍ່ເປັນຫຍັງເດີ້ ສູ້ໆໃນຂໍ້ຕໍ່ໄປ!',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isAnswerCorrect
                                      ? const Color(0xFF43A047)
                                      : const Color(0xFFE53935),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isAnswerCorrect
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFFC62828),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                          onPressed: _nextQuestion,
                          child: Text(
                            currentQuestionIndex < questions.length - 1
                                ? 'ຕໍ່ໄປ'
                                : 'ສຳເລັດ',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fade().slideY(begin: 0.2, end: 0),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet explaining Lao TTS limitation and guiding to Play Store
class _LaoTtsInstallSheet extends StatelessWidget {
  final VoidCallback onOpenPlayStore;
  final VoidCallback onOpenSettings;
  final VoidCallback onClose;

  const _LaoTtsInstallSheet({
    required this.onOpenPlayStore,
    required this.onOpenSettings,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44, height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('\uD83D\uDD0A', style: TextStyle(fontSize: 40)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3CD),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFFCA28)),
                ),
                child: const Text(
                  'Google TTS \u0e9a\u0ecd\u0ec8\u0eae\u0ead\u0e87\u0eae\u0eb1\u0e9a\u0ea5າວ',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFF57F17)),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 14),
          const Text(
            '\u0e95\u0ec9\u0ead\u0e87\u0e95\u0eb4\u0e94\u0e95\u0eb1\u0ec9\u0e87 App \u0eaa\u0ebd\u0e87\u0ea5າວ',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 150.ms),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(14)),
            child: const Text(
              'Google TTS \u0e97\u0eb5\u0ec8\u0e95\u0eb4\u0e94\u0e95\u0eb1\u0ec9\u0e87\u0ec3\u0e99 Android \u0e9a\u0ecd\u0ec8\u0ea1\u0eb5\u0eaa\u0ebd\u0e87\u0e9eາ\u0eaaາ\u0ea5າວ.\n\u0e95\u0ec9\u0ead\u0e87 download App \u0eaa\u0ebd\u0e87\u0ea5າວ \u0e88າກ Play Store \u0e81\u0ec8\u0ead\u0e99.',
              style: TextStyle(fontSize: 13, color: Color(0xFF444466), height: 1.6),
              textAlign: TextAlign.center,
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 16),
          _StepTile(number: '1', text: 'ຊອກ App Lao TTS ຢູ່ Play Store', emoji: '\uD83C\uDFEA'),
          const SizedBox(height: 8),
          _StepTile(number: '2', text: 'ດາວໂຫຼດ ແລະ ຕິດຕັ້ງ App ສຽງລາວ', emoji: '\uD83D\uDCE5'),
          const SizedBox(height: 8),
          _StepTile(number: '3', text: 'ການຕັ້ງຄ່າ → ສຽງ → TTS → ເລືອກ engine ສຽງລາວ', emoji: '\u2699\uFE0F'),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onOpenPlayStore,
              icon: const Icon(Icons.store_rounded, size: 20),
              label: const Text('ຊອກ App ສຽງລາວ ໃນ Play Store', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF01875F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.3, end: 0),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onOpenSettings,
              icon: const Icon(Icons.settings_rounded, size: 18, color: Color(0xFF3E8EF7)),
              label: const Text('ເປີດການຕັ້ງຄ່າ TTS', style: TextStyle(fontSize: 14, color: Color(0xFF3E8EF7), fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: Color(0xFF3E8EF7)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 6),
          TextButton(onPressed: onClose, child: const Text('ປິດ', style: TextStyle(color: Colors.grey, fontSize: 14))),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {

  final String number;
  final String text;
  final String emoji;

  const _StepTile({
    required this.number,
    required this.text,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFF3E8EF7),
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF333355),
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(emoji, style: const TextStyle(fontSize: 20)),
        ],
      ),
    ).animate().fadeIn(delay: 350.ms);
  }
}
