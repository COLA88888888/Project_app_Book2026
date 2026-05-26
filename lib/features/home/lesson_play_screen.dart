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

  QuizQuestion({
    required this.questionText,
    required this.options,
    required this.correctIndex,
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
  bool _isCheckingLao = true;

  @override
  void initState() {
    super.initState();
    _loadLesson();
    _initTtsPlayer();
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

    // Generate unique child-friendly textbook questions based on the lesson title
    if (title.contains('ພະຍັນຊະນະ ກ, ຂ & ສະຫຼະ xະ, xາ')) {
      questions = [
        QuizQuestion(
          questionText: 'ຄຳສັບໃດເກີດຈາກພະຍັນຊະນະ "ກ" ປະສົມກັບສະຫຼະ "າ"? 🐔',
          options: ['ກະ', 'ກາ', 'ຂະ', 'ຂາ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຄຳສັບໃດເກີດຈາກພະຍັນຊະນະ "ຂ" ປະສົມກັບສະຫຼະ "ະ"? 🍉',
          options: ['ຂາ', 'ກະ', 'ຂະ', 'ກາ'],
          correctIndex: 2,
        ),
        QuizQuestion(
          questionText: 'ຮູບພາບ "ກາ" 🐦 ປະກອບດ້ວຍພະຍັນຊະນະ ແລະ ສະຫຼະໃດ?',
          options: ['ກ + ສະຫຼະ ະ', 'ຂ + ສະຫຼະ າ', 'ກ + ສະຫຼະ າ', 'ຂ + ສະຫຼະ ະ'],
          correctIndex: 2,
        ),
      ];
    } else if (title.contains('ພະຍັນຊະນະ ຄ, ງ & ສະຫຼະ xິ, xີ')) {
      questions = [
        QuizQuestion(
          questionText: 'ຄຳສັບໃດເກີດຈາກພະຍັນຊະນະ "ຄ" ປະສົມກັບສະຫຼະ "ີ"? 🔑',
          options: ['ຄິ', 'ຄີ', 'ງິ', 'ງີ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຄຳສັບໃດເກີດຈາກພະຍັນຊະນະ "ງ" ປະສົມກັບສະຫຼະ "ິ"? 🐍',
          options: ['ງີ', 'ຄິ', 'ງິ', 'ຄີ'],
          correctIndex: 2,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ງີ" ອອກສຽງສະຫຼະໃດ? 🌟',
          options: ['ສະຫຼະ ິ (ອິ)', 'ສະຫຼະ ີ (ອີ)', 'ສະຫຼະ ະ (ອະ)', 'ສະຫຼະ າ (ອາ)'],
          correctIndex: 1,
        ),
      ];
    } else if (title.contains('ພະຍັນຊະນະ ຈ, ສ & ສະຫຼະ xຶ, xື')) {
      questions = [
        QuizQuestion(
          questionText: 'ຄຳສັບໃດເກີດຈາກພະຍັນຊະນະ "ຈ" ປະສົມກັບສະຫຼະ "ື"? ✍️',
          options: ['ຈຶ', 'ຈື', 'ສຶ', 'ສື'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຄຳສັບໃດເກີດຈາກພະຍັນຊະນະ "ສ" ປະສົມກັບສະຫຼະ "ຶ"? 🐯',
          options: ['ສື', 'ຈຶ', 'ສຶ', 'ຈື'],
          correctIndex: 2,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ມື" ✋ ປະກອບດ້ວຍພະຍັນຊະນະ "ມ" ປະສົມກັບສະຫຼະໃດ?',
          options: ['ສະຫຼະ  ຶ', 'ສະຫຼະ  ື', 'ສະຫຼະ  ິ', 'ສະຫຼະ  ີ'],
          correctIndex: 1,
        ),
      ];
    } else if (title.contains('ພະຍັນຊະນະ ຊ, ຍ & ສະຫຼະ xຸ, xູ')) {
      questions = [
        QuizQuestion(
          questionText: 'ຄຳສັບໃດເກີດຈາກພະຍັນຊະນະ "ຊ" ປະສົມກັບສະຫຼະ "ູ"? 🌟',
          options: ['ຊຸ', 'ຊູ', 'ຍຸ', 'ຍູ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ຍຸ" 🦟 ອອກສຽງສະຫຼະໃດ?',
          options: ['ສະຫຼະ ຸ (ອຸ)', 'ສະຫຼະ ູ (ອູ)', 'ສະຫຼະ ະ', 'ສະຫຼະ າ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຮູບພາບ "ຊູມື" 🙋‍♂️ ປະກອບດ້ວຍຄຳສັບໃດແດ່?',
          options: ['ຊຸມື', 'ຊູມື', 'ຍຸມື', 'ຍູມື'],
          correctIndex: 1,
        ),
      ];
    } else if (title.contains('ພະຍັນຊະນະ ດ, ຕ & ສະຫຼະ ເxະ, ເx')) {
      questions = [
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ເຕະ" ⚽ (ເຕະບານ) ປະກອບດ້ວຍສະຫຼະໃດ?',
          options: ['ສະຫຼະ ເx', 'ສະຫຼະ ເxະ', 'ສະຫຼະ ແx', 'ສະຫຼະ ແxະ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຄຳສັບໃດເກີດຈາກພະຍັນຊະນະ "ດ" ປະສົມກັບສະຫຼະ "ເx"? 🕯️',
          options: ['ເດະ', 'ເດ', 'ເຕະ', 'ເຕ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ຕາ" 👁️ ປະສົມກັບສະຫຼະ "ເx" ຈະອ່ານວ່າແນວໃດ?',
          options: ['ເຕະ', 'ເຕ', 'ແຕະ', 'ແຕ'],
          correctIndex: 1,
        ),
      ];
    } else if (title.contains('ພະຍັນຊະນະ ຖ, ທ & ສະຫຼະ ແxະ, ແx')) {
      questions = [
        QuizQuestion(
          questionText: 'ຄຳສັບໃດເກີດຈາກພະຍັນຊະນະ "ທ" ປະສົມກັບສະຫຼະ "ແx"? ✏️',
          options: ['ແທະ', 'ແທ', 'ແຖະ', 'ແຖ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ແກະ" 🐑 ອອກສຽງສະຫຼະດຽວກັນກັບຄຳໃດ?',
          options: ['ແຖະ', 'ແຖ', 'ແທ', 'ແບ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ແທ" ອອກສຽງສະຫຼະໃດ? 🌟',
          options: ['ສະຫຼະ ແxະ', 'ສະຫຼະ ແx', 'ສະຫຼະ ເxະ', 'ສະຫຼະ ເx'],
          correctIndex: 1,
        ),
      ];
    } else if (title.contains('ພະຍັນຊະນະ ນ, ບ & ສະຫຼະ ໂxະ, ໂx')) {
      questions = [
        QuizQuestion(
          questionText: 'ຄຳສັບໃດເກີດຈາກພະຍັນຊະນະ "ບ" ປະສົມກັບສະຫຼະ "ໂx"? 🐂',
          options: ['ໂບະ', 'ໂບ', 'ໂນະ', 'ໂນ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ໂນ" ອອກສຽງສະຫຼະໃດ? 🌟',
          options: ['ສະຫຼະ ໂxະ', 'ສະຫຼະ ໂx', 'ສະຫຼະ xົ', 'ສະຫຼະ xົວ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ໂຕະ" 🪵 ອອກສຽງສະຫຼະດຽວກັນກັບຄຳໃດ?',
          options: ['ໂນະ', 'ໂນ', 'ໂບ', 'ໂບະ'],
          correctIndex: 3,
        ),
      ];
    } else if (title.contains('ພະຍັນຊະນະ ປ, ຜ & ສະຫຼະ ເxາະ, xໍ')) {
      questions = [
        QuizQuestion(
          questionText: 'ຄຳສັບໃດເກີດຈາກພະຍັນຊະນະ "ປ" ປະສົມກັບສະຫຼະ "xໍ"? 💎',
          options: ['ເປາະ', 'ປໍ', 'ເຜາະ', 'ຜໍ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ເປາະ" ປະກອບດ້ວຍພະຍັນຊະນະ "ປ" ປະສົມກັບສະຫຼະໃດ? 📖',
          options: ['ສະຫຼະ ເxາະ', 'ສະຫຼະ xໍ', 'ສະຫຼະ ໂxະ', 'ສະຫຼະ ໂx'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ຜໍ" ອອກສຽງສະຫຼະໃດ? 🌟',
          options: ['ສະຫຼະ ເxາະ', 'ສະຫຼະ xໍ', 'ສະຫຼະ ະ', 'ສະຫຼະ າ'],
          correctIndex: 1,
        ),
      ];
    } else if (title.contains('ພະຍັນຊະນະ ຝ, ພ & ສະຫຼະ ເxີ, ເxີຍ')) {
      questions = [
        QuizQuestion(
          questionText: 'ຄຳສັບໃດເກີດຈາກພະຍັນຊະນະ "ພ" ປະສົມກັບສະຫຼະ "ເxີ"? 🌸',
          options: ['ເພີ', 'ເຝີ', 'ເພີຍ', 'ເຝີຍ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ເຝີ" 🍜 (ອາຫານຍອດນິຍົມ) ອອກສຽງສະຫຼະໃດ?',
          options: ['ສະຫຼະ ເxີ', 'ສະຫຼະ ເxີຍ', 'ສະຫຼະ ເx', 'ສະຫຼະ ແx'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ເພີຍ" ປະກອບດ້ວຍພະຍັນຊະນະໃດ? 🌟',
          options: ['ພ', 'ຝ', 'ປ', 'ຜ'],
          correctIndex: 0,
        ),
      ];
    } else if (title.contains('ພະຍັນຊະນະ ຟ, ມ & ສະຫຼະ xົ, xົວ')) {
      questions = [
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ມົວ" 🌫️ ປະກອບດ້ວຍພະຍັນຊະນະ ແລະ ສະຫຼະໃດ?',
          options: ['ມ + ສະຫຼະ xົ', 'ມ + ສະຫຼະ xົວ', 'ຟ + ສະຫຼະ xົ', 'ຟ + ສະຫຼະ xົວ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຄຳສັບໃດເກີດຈາກພະຍັນຊະນະ "ມ" ປະສົມກັບສະຫຼະ "xົ" ພ້ອມຕົວສະກົດ "ດ"? 🐜',
          options: ['ມົດ', 'ມົວ', 'ຟົດ', 'ຟົວ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ມົດ" 🐜 ອອກສຽງສະຫຼະໃດ?',
          options: ['ສະຫຼະ xົ', 'ສະຫຼະ xົວ', 'ສະຫຼະ ະ', 'ສະຫຼະ າ'],
          correctIndex: 0,
        ),
      ];
    } else if (title.contains('ພະຍັນຊະນະ ຢ, ຣ & ສະຫຼະ ເxຍ, ເxືອ')) {
      questions = [
        QuizQuestion(
          questionText: 'ຄຳວ່າ "\u0ec0\u0eab\u0ebc\u0eb7\u0ea5" 🚢 ປະກອບດ້ວຍພະຍັນຊະນະ ແລະ ສະຫຼະໃດ?',
          options: ['ຣ + ສະຫຼະ ເxຍ', 'ຣ + ສະຫຼະ ເxືອ', 'ຢ + ສະຫຼະ ເxຍ', 'ຢ + ສະຫຼະ ເxືອ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ເຢຍ" (ເຢຍລະມັນ) ອອກສຽງສະຫຼະໃດ? 🌟',
          options: ['ສະຫຼະ ເxຍ', 'ສະຫຼະ ເxືອ', 'ສະຫຼະ ເxີ', 'ສະຫຼະ ເx'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຮູບພາບ "ເຮືອ" ⛵ ອອກສຽງພະຍັນຊະນະໃດ?',
          options: ['ຮ', 'ຣ', 'ລ', 'ວ'],
          correctIndex: 0,
        ),
      ];
    } else if (title.contains('ພະຍັນຊະນະ ລ, ວ & ສະຫຼະ xຳ, ໄx, ໃx, ເxົາ')) {
      questions = [
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ລຳ" 💃 (ລຳວົງ) ປະກອບດ້ວຍສະຫຼະໃດ?',
          options: ['ສະຫຼະ xຳ', 'ສະຫຼະ xໄ', 'ສະຫຼະ xໃ', 'ສະຫຼະ xົາ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ໃບໄມ້" 🍃 ປະກອບດ້ວຍສະຫຼະໃດແດ່?',
          options: ['ສະຫຼະ ໃx ແລະ ສະຫຼະ ໄx', 'ສະຫຼະ xຳ ແລະ ສະຫຼະ ເxົາ', 'ສະຫຼະ ະ ແລະ ສະຫຼະ າ', 'ສະຫຼະ  ິ ແລະ ສະຫຼະ  ີ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຄຳສັບໃດເກີດຈາກພະຍັນຊະນະ "ວ" ປະສົມກັບສະຫຼະ "xົາ" ພ້ອມໄມ້ໂທ? 🗣️',
          options: ['ເວົາ', 'ເວົ້າ', 'ໄວ', 'ໃບ'],
          correctIndex: 1,
        ),
      ];
    } else if (title.contains('ພະຍັນຊະນະ ຫ, ອ, ຮ & ທວນຄືນສະຫຼະທັງໝົດ')) {
      questions = [
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ຫູ" 👂 ປະກອບດ້ວຍພະຍັນຊະນະໃດ?',
          options: ['ຫ', 'ອ', 'ຮ', 'ລ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ອ່ານ" 📖 ປະກອບດ້ວຍພະຍັນຊະນະໃດ?',
          options: ['ອ', 'ຮ', 'ຫ', 'ນ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຮູບພາບ "ຮາ" (ຫົວຮາໆ) 😆 ອອກສຽງພະຍັນຊະນະໃດ?',
          options: ['ຮ', 'ຫ', 'ອ', 'ລ'],
          correctIndex: 0,
        ),
      ];
    } else if (title.contains('ວັນນະຍຸດ ໄມ້ເອກ (x່) ແລະ ໄມ້ໂທ (x້)')) {
      questions = [
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ປ່າ" 🌲 ປະກອບດ້ວຍວັນນະຍຸດໃດ?',
          options: ['ໄມ້ເອກ (x່)', 'ໄມ້ໂທ (x້)', 'ໄມ້ຕີ (x໊)', 'ບໍ່ມີວັນນະຍຸດ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ມ້າ" 🐎 ປະກອບດ້ວຍວັນນະຍຸດໃດ?',
          options: ['ໄມ້ເອກ (x່)', 'ໄມ້ໂທ (x້)', 'ໄມ້ຕີ (x໊)', 'ບໍ່ມີວັນນະຍຸດ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ພໍ່" 👨‍👦 ປະກອບດ້ວຍວັນນະຍຸດໃດ?',
          options: ['ໄມ້ເອກ (x່)', 'ໄມ້ໂທ (x້)', 'ໄມ້ຕີ', 'ບໍ່ມີ'],
          correctIndex: 0,
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
    } else if (title.contains('ພະຍັນຊະນະປະສົມ ໝ, ຫຼ')) {
      questions = [
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ໝາ" 🐶 ອອກສຽງພະຍັນຊະນະປະສົມຕົວໃດ?',
          options: ['ໝ', 'ຫຼ', 'ໜ', 'ໝາ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ຫຼານ" 👦 ອອກສຽງພະຍັນຊະນະປະສົມຕົວໃດ?',
          options: ['ຫຼ', 'ໝ', 'ໜ', 'ຫຍ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຮູບພາບ "ໝໍ" 🩺 ອອກສຽງພະຍັນຊະນະປະສົມຕົວໃດ?',
          options: ['ໝ', 'ຫຼ', 'ໜ', 'ຫງ'],
          correctIndex: 0,
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
    } else if (title.contains('ຄຳຄຸນນາມ')) {
      questions = [
        QuizQuestion(
          questionText: 'ຄຳໃດແມ່ນ "ຄຳຄຸນນາມ" (ບອກລັກສະນະ)? 🎨',
          options: ['ໃຫຍ່', 'ແລ່ນ', 'ປຶ້ມ', 'ແລະ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ປະໂຫຍກໃດຕໍ່ໄປນີ້ຖືກຕ້ອງຕາມຫຼັກໄວຍາກອນ? ✍️',
          options: ['ຂ້ອຍກິນເຂົ້າ.', 'ກິນຂ້ອຍເຂົ້າ.', 'ເຂົ້າກິນຂ້ອຍ.', 'ກິນເຂົ້າຂ້ອຍ.'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ຫວານ" 🍉 (ໝາກໄມ້ຫວານ) ແມ່ນຄຳປະເພດໃດ?',
          options: ['ຄຳຄຸນນາມ', 'ຄຳນາມ', 'ຄຳກຳມະ', 'ຄຳແທນນາມ'],
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
    } else if (title.contains('ການນັບຈຳນວນ 1')) {
      questions = [
        QuizQuestion(
          questionText: 'ມີໝາກແອັບເປິ້ນຈັກໜ່ວຍ? 🍎🍎🍎',
          options: ['2 ໜ່ວຍ', '3 ໜ່ວຍ', '4 ໜ່ວຍ', '5 ໜ່ວຍ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ມີໝາກກ້ວຍຈັກໜ່ວຍ? 🍌🍌🍌🍌🍌',
          options: ['3 ໜ່ວຍ', '4 ໜ່ວຍ', '5 ໜ່ວຍ', '6 ໜ່ວຍ'],
          correctIndex: 2,
        ),
        QuizQuestion(
          questionText: 'ຕົວເລກໃດແມ່ນ "ເລກເຈັດ"? 🔢',
          options: ['5', '6', '7', '8'],
          correctIndex: 2,
        ),
      ];
    } else if (title.contains('ການປຽບທຽບຈຳນວນ')) {
      questions = [
        QuizQuestion(
          questionText: 'ເລກ 5 ກັບ ເລກ 8 ຕົວເລກໃດມີຄ່າຫຼາຍກວ່າ? 🔢',
          options: ['ເລກ 5', 'ເລກ 8', 'ເທົ່າກັນ', 'ບໍ່ມີຂໍ້ຖືກ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ໝາກໄມ້ 3 ໜ່ວຍ ກັບ 1 ໜ່ວຍ, ເບື້ອງໃດໜ້ອຍກວ່າ? 🍊',
          options: [
            'ເບື້ອງ 3 ໜ່ວຍ',
            'ເບື້ອງ 1 ໜ່ວຍ',
            'ເທົ່າກັນ',
            'ບໍ່ມີຂໍ້ຖືກ',
          ],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ເລກ 10 ກັບ ເລກ 10 ມີຄ່າແນວໃດຕໍ່ກັນ? 💎',
          options: ['10 ຫຼາຍກວ່າ', '10 ໜ້ອຍກວ່າ', 'ເທົ່າກັນ', 'ບໍ່ມີຂໍ້ຖືກ'],
          correctIndex: 2,
        ),
      ];
    } else if (title.contains('ການບວກຈຳນວນ')) {
      questions = [
        QuizQuestion(
          questionText: '2 + 3 ເທົ່າກັບເທົ່າໃດນໍ້? 🤔',
          options: ['4', '5', '6', '7'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: '4 + 4 ເທົ່າກັບເທົ່າໃດນໍ້? 🌟',
          options: ['6', '7', '8', '9'],
          correctIndex: 2,
        ),
        QuizQuestion(
          questionText: 'ມີໝາກກ້ຽງ 2 🍊🍊 ບວກຕື່ມ 1 🍊 ເປັນຈັກໜ່ວຍ?',
          options: ['2 ໜ່ວຍ', '3 ໜ່ວຍ', '4 ໜ່ວຍ', '5 ໜ່ວຍ'],
          correctIndex: 1,
        ),
      ];
    } else if (title.contains('ການລົບຈຳນວນ')) {
      questions = [
        QuizQuestion(
          questionText: '5 - 2 ເທົ່າກັບເທົ່າໃດນໍ້? ✏️',
          options: ['2', '3', '4', '5'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: '7 - 4 ເທົ່າກັບເທົ່າໃດນໍ້? 💎',
          options: ['2', '3', '4', '5'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ມີໝາກກ້ວຍ 4 🍌 ຫຼານກິນໄປ 1 🍌 ເຫຼືອຈັກໜ່ວຍ?',
          options: ['2', '3', '4', '5'],
          correctIndex: 1,
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
    } else if (title.contains('ການລົບເລກສອງຫຼັກ')) {
      questions = [
        QuizQuestion(
          questionText: '32 - 15 ເທົ່າກັບເທົ່າໃດນໍ້? 🧮',
          options: ['16', '17', '18', '19'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: '45 - 28 ເທົ່າກັບເທົ່າໃດນໍ້? ✏️',
          options: ['15', '16', '17', '18'],
          correctIndex: 2,
        ),
        QuizQuestion(
          questionText: '20 - 7 ເທົ່າກັບເທົ່າໃດນໍ້? 🌟',
          options: ['11', '12', '13', '14'],
          correctIndex: 2,
        ),
      ];
    } else if (title.contains('ສູດຄູນ')) {
      questions = [
        QuizQuestion(
          questionText: '2 x 3 ເທົ່າກັບເທົ່າໃດນໍ້? 🧮',
          options: ['4', '5', '6', '7'],
          correctIndex: 2,
        ),
        QuizQuestion(
          questionText: '3 x 3 ເທົ່າກັບເທົ່າໃດນໍ້? 🌟',
          options: ['6', '8', '9', '10'],
          correctIndex: 2,
        ),
        QuizQuestion(
          questionText: '5 x 2 ມີຄ່າເທົ່າໃດ? 💎',
          options: ['8', '10', '12', '15'],
          correctIndex: 1,
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
    } else if (title.contains('ໂຈດອ່ານ 9') || title.contains('ສະຫຼະພິເສດ')) {
      questions = [
        QuizQuestion(questionText: 'ລຳ 💃 ໃຊ້ສະຫຼະໃດ?', options: ['xໄ', 'xໃ', 'xຳ', 'xົ'], correctIndex: 2),
        QuizQuestion(questionText: 'ສະຫຼະ xໄ ແລະ xໃ ອອກສຽງ...? 🌟', options: ['ໄອ ສຽງດຽວກັນ', 'ໄ ສຽງຍາວ', 'ໃ ສຽງສັ້ນ', 'ຕ່າງກັນ'], correctIndex: 0),
        QuizQuestion(questionText: 'ມົດ 🐜 ໃຊ້ສະຫຼະໃດ?', options: ['xຳ', 'xົ', 'xົວ', 'ເxຍ'], correctIndex: 1),
        QuizQuestion(questionText: 'ເຮືອ ⛵ ໃຊ້ສະຫຼະໃດ?', options: ['ເxຍ', 'ເxືອ', 'xົວ', 'xໃ'], correctIndex: 1),
        QuizQuestion(questionText: 'ເຢຍ ໃຊ້ສະຫຼະໃດ? 🌟', options: ['ເxຍ', 'ເxືອ', 'xໄ', 'xຳ'], correctIndex: 0),
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

    final prefs = await SharedPreferences.getInstance();
    currentUserId = prefs.getInt('current_user_id') ?? 1;

    setState(() {
      lesson = matched;
      isLoading = false;
    });
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
      });
    } else {
      // Save progress to SQLite
      await DatabaseHelper.instance.saveProgress(
        currentUserId,
        lesson!.id!,
        score,
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
                'ຫຼານແກ້ເລກໄດ້ຄະແນນເຕັມ!',
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
                  score,
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
              const SizedBox(height: 36),

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
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textColor,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  )
                  .animate(key: ValueKey(currentQuestionIndex))
                  .fade()
                  .scale(curve: Curves.easeOutBack),
              const SizedBox(height: 36),

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
