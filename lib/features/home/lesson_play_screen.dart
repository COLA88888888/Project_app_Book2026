import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/database/db_helper.dart';
import '../../core/models/lesson.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:audioplayers/audioplayers.dart';

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
  bool get isReadingMode => lesson != null && lesson!.grade == 'P1' && lesson!.subject == 'ການອ່ານ';

  @override
  void initState() {
    super.initState();
    _loadLesson();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }




  Future<void> _loadLesson() async {
    final id = int.tryParse(widget.lessonId);
    if (id == null) return;

    final allLessons = await DatabaseHelper.instance.getAllLessons();
    final matched = allLessons.firstWhere((l) => l.id == id);

    final title = matched.title;

    _populateQuestions(title, matched.subject, matched.grade);

    final prefs = await SharedPreferences.getInstance();
    currentUserId = prefs.getInt('current_user_id') ?? 1;

    setState(() {
      lesson = matched;
      isLoading = false;
    });
  }

  void _populateQuestions(String title, String subject, String grade) {
    if (title.contains('ບົດທີ 9: ປະສົມພະຍັນຊະນະ ກັບ ສະຫຼະສຽງສັ້ນ xະ, xິ, xຶ, xຸ 🍎')) {
      questions = [
        QuizQuestion(
          questionText: 'ກ + xະ = ?',
          options: ['ກາ', 'ກະ', 'ກິ', 'ກຶ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຈ + xຸ = ?',
          options: ['ຈະ', 'ຈິ', 'ຈຶ', 'ຈຸ'],
          correctIndex: 3,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ສຶ" ປະກອບດ້ວຍ...?',
          options: ['ສ + xະ', 'ສ + xິ', 'ສ + xຶ', 'ສ + xຸ'],
          correctIndex: 2,
        ),
      ];
    } else if (title.contains('ບົດທີ 10: ປະສົມພະຍັນຊະນະ ກັບ ສະຫຼະສຽງຍາວ xາ, xີ, xື, xູ 🌾')) {
      questions = [
        QuizQuestion(
          questionText: 'ດ + xີ = ? 👍',
          options: ['ດາ', 'ດີ', 'ດື', 'ດູ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ປ + xູ = ? 🦀',
          options: ['ປາ', 'ປີ', 'ປື', 'ປູ'],
          correctIndex: 3,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ມື" ປະກອບດ້ວຍ...?',
          options: ['ມ + xາ', 'ມ + xີ', 'ມ + xື', 'ມ + xູ'],
          correctIndex: 2,
        ),
      ];
    } else if (title.contains('ບົດທີ 11: ປະສົມພະຍັນຊະນະ ກັບ ສະຫຼະ ເx, ແx, ໂx, xໍ 🎀')) {
      questions = [
        QuizQuestion(
          questionText: 'ບ + ໂx = ?',
          options: ['ເບ', 'ແບ', 'ໂບ', 'ບໍ'],
          correctIndex: 2,
        ),
        QuizQuestion(
          questionText: 'ປ + xໍ = ?',
          options: ['ເປ', 'ແປ', 'ໂປ', 'ປໍ'],
          correctIndex: 3,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ແບ" ປະກອບດ້ວຍ...?',
          options: ['ບ + ເx', 'ບ + ແx', 'ບ + ໂx', 'ບ + xໍ'],
          correctIndex: 1,
        ),
      ];
    } else if (title.contains('ບົດທີ 12: ປະສົມພະຍັນຊະນະ ກັບ ສະຫຼະພິເສດ xຳ, ໄx, ໃx, ເxົາ 🔥')) {
      questions = [
        QuizQuestion(
          questionText: 'ລ + xຳ = ?',
          options: ['ໄລ', 'ໃລ', 'ລຳ', 'ເລົາ'],
          correctIndex: 2,
        ),
        QuizQuestion(
          questionText: 'ຟ + ໄx = ?',
          options: ['ຟຳ', 'ໄຟ', 'ໃຟ', 'ເຟົາ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ໃບ" ປະກອບດ້ວຍ...?',
          options: ['ບ + xຳ', 'ບ + ໄx', 'ບ + ໃx', 'ບ + ເxົາ'],
          correctIndex: 2,
        ),
      ];
    } else if (title.contains('ບົດທີ 13: ປະສົມພະຍັນຊະນະ ກັບ ອັກສອນປະສົມ ຫງ, ຫຍ, ໜ, ໝ, ຫຼ, ຫວ 🐶') || title.contains('ປະສົມພະຍັນຊະນະ ກັບ ອັກສອນປະສົມ')) {
      questions = [
        QuizQuestion(
          questionText: 'ໝ + າ = ?',
          options: ['ໜາ', 'ໝາ', 'ຫຼາ', 'ຫວາ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຫຼ + xີ = ?',
          options: ['ຫຼິ', 'ຫຼີ', 'ໜິ', 'ໜີ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ໜູ" ປະກອບດ້ວຍ...?',
          options: ['ໜ + xູ', 'ໝ + xູ', 'ຫຼ + xູ', 'ຫວ + xູ'],
          correctIndex: 0,
        ),
      ];
    } else if (title.contains('ບົດທີ 14: ປະສົມພະຍັນຊະນະ ກັບ ວັນນະຍຸດ ໄມ້ເອກ (x່) ແລະ ໄມ້ໂທ (x້) 🌲') || title.contains('ປະສົມພະຍັນຊະນະ ກັບ ວັນນະຍຸດ')) {
      questions = [
        QuizQuestion(
          questionText: 'ປ + າ + ໄມ້ເອກ (x່) = ?',
          options: ['ປາ', 'ປ່າ', 'ປ້າ', 'ປ໊າ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ມ + າ + ໄມ້ໂທ (x້) = ?',
          options: ['ມາ', 'ມ່າ', 'ມ້າ', 'ມ໊າ'],
          correctIndex: 2,
        ),
        QuizQuestion(
          questionText: 'ພ + ໍ + ໄມ້ເອກ (x່) = ?',
          options: ['ພໍ', 'ພໍ່', 'ພໍ້', 'ພ໊ໍ'],
          correctIndex: 1,
        ),
      ];
    } else if (title.contains('ບົດທີ 1: ອ່ານພະຍັນຊະນະ ກ, ຂ, ຄ, ງ')) {
      questions = [
        QuizQuestion(questionText: 'ກ', options: [], correctIndex: -1, readingGuide: 'ພະຍັນຊະນະ ກ (ກໍ)'),
        QuizQuestion(questionText: 'ຂ', options: [], correctIndex: -1, readingGuide: 'ພະຍັນຊະນະ ຂ (ຂໍ)'),
        QuizQuestion(questionText: 'ຄ', options: [], correctIndex: -1, readingGuide: 'ພະຍັນຊະນະ ຄ (ຄໍ)'),
        QuizQuestion(questionText: 'ງ', options: [], correctIndex: -1, readingGuide: 'ພະຍັນຊະນະ ງ (ງໍ)'),
        QuizQuestion(questionText: 'ກາ', options: [], correctIndex: -1, readingGuide: 'ກ + າ = ກາ'),
        QuizQuestion(questionText: 'ຂາ', options: [], correctIndex: -1, readingGuide: 'ຂ + າ = ຂາ'),
        QuizQuestion(questionText: 'ຄູ', options: [], correctIndex: -1, readingGuide: 'ຄ + ູ = ຄູ'),
        QuizQuestion(questionText: 'ງູ', options: [], correctIndex: -1, readingGuide: 'ງ + ູ = ງູ'),
      ];
    } else if (title.contains('ບົດທີ 2: ອ່ານພະຍັນຊະນະ ຈ, ສ, ຊ, ຍ')) {
      questions = [
        QuizQuestion(questionText: 'ຈ', options: [], correctIndex: -1, readingGuide: 'ພະຍັນຊະນະ ຈ (ຈໍ)'),
        QuizQuestion(questionText: 'ສ', options: [], correctIndex: -1, readingGuide: 'ພະຍັນຊະນະ ສ (ສໍ)'),
        QuizQuestion(questionText: 'ຊ', options: [], correctIndex: -1, readingGuide: 'ພະຍັນຊະນະ ຊ (ຊໍ)'),
        QuizQuestion(questionText: 'ຍ', options: [], correctIndex: -1, readingGuide: 'ພະຍັນຊະນະ ຍ (ຍໍ)'),
        QuizQuestion(questionText: 'ຈາ', options: [], correctIndex: -1, readingGuide: 'ຈ + າ = ຈາ'),
        QuizQuestion(questionText: 'ສີ', options: [], correctIndex: -1, readingGuide: 'ສ + ີ = ສີ'),
        QuizQuestion(questionText: 'ຊູ', options: [], correctIndex: -1, readingGuide: 'ຊ + ູ = ຊູ'),
        QuizQuestion(questionText: 'ຍຸ', options: [], correctIndex: -1, readingGuide: 'ຍ + ຸ = ຍຸ'),
      ];
    } else if (title.contains('ບົດທີ 3: ອ່ານພະຍັນຊະນະ ດ, ຕ, ຖ, ທ')) {
      questions = [
        QuizQuestion(questionText: 'ດ', options: [], correctIndex: -1, readingGuide: 'ພະຍັນຊະນະ ດ (ດໍ)'),
        QuizQuestion(questionText: 'ຕ', options: [], correctIndex: -1, readingGuide: 'ພະຍັນຊະນະ ຕ (ຕໍ)'),
        QuizQuestion(questionText: 'ຖ', options: [], correctIndex: -1, readingGuide: 'ພະຍັນຊະນະ ຖ (ຖໍ)'),
        QuizQuestion(questionText: 'ທ', options: [], correctIndex: -1, readingGuide: 'ພະຍັນຊະນະ ທ (ທໍ)'),
        QuizQuestion(questionText: 'ດີ', options: [], correctIndex: -1, readingGuide: 'ດ + ີ = ດີ'),
        QuizQuestion(questionText: 'ຕາ', options: [], correctIndex: -1, readingGuide: 'ຕ + າ = ຕາ'),
        QuizQuestion(questionText: 'ຖູ', options: [], correctIndex: -1, readingGuide: 'ຖ + ູ = ຖູ'),
        QuizQuestion(questionText: 'ທາ', options: [], correctIndex: -1, readingGuide: 'ທ + າ = ທາ'),
      ];
    } else if (title.contains('ບົດທີ 4: ອ່ານພະຍັນຊະນະ ນ, ບ, ປ, ຜ')) {
      questions = [
        QuizQuestion(questionText: 'ນ', options: [], correctIndex: -1, readingGuide: 'ພະຍັນຊະນະ ນ (ນໍ)'),
        QuizQuestion(questionText: 'ບ', options: [], correctIndex: -1, readingGuide: 'ພະຍັນຊະນະ ບ (ບໍ)'),
        QuizQuestion(questionText: 'ປ', options: [], correctIndex: -1, readingGuide: 'ພະຍັນຊະນະ ປ (ປໍ)'),
        QuizQuestion(questionText: 'ຜ', options: [], correctIndex: -1, readingGuide: 'ພະຍັນຊະນະ ຜ (ຜໍ)'),
        QuizQuestion(questionText: 'ນາ', options: [], correctIndex: -1, readingGuide: 'ນ + າ = ນາ'),
        QuizQuestion(questionText: 'ໂບ', options: [], correctIndex: -1, readingGuide: 'ບ + ໂx = ໂບ'),
        QuizQuestion(questionText: 'ປູ', options: [], correctIndex: -1, readingGuide: 'ປ + ູ = ປູ'),
        QuizQuestion(questionText: 'ຜີ', options: [], correctIndex: -1, readingGuide: 'ຜ + ີ = ຜີ'),
      ];
    } else if (title.contains('ບົດທີ 5: ອ່ານພະຍັນຊະນະ ຝ, ພ, ຟ, ມ')) {
      questions = [
        QuizQuestion(questionText: 'ຝ', options: [], correctIndex: -1, readingGuide: 'ພະຍັນຊະນະ ຝ (ຝໍ)'),
        QuizQuestion(questionText: 'ພ', options: [], correctIndex: -1, readingGuide: 'ພະຍັນຊະນະ ພ (ພໍ)'),
        QuizQuestion(questionText: 'ຟ', options: [], correctIndex: -1, readingGuide: 'ພະຍັນຊະນະ ຟ (ຟໍ)'),
        QuizQuestion(questionText: 'ມ', options: [], correctIndex: -1, readingGuide: 'ພະຍັນຊະນະ ມ (ມໍ)'),
        QuizQuestion(questionText: 'ຝາ', options: [], correctIndex: -1, readingGuide: 'ຝ + າ = ຝາ'),
        QuizQuestion(questionText: 'ພໍ່', options: [], correctIndex: -1, readingGuide: 'ພ + ໍ + ໄມ້ເອກ = ພໍ່'),
        QuizQuestion(questionText: 'ໄຟ', options: [], correctIndex: -1, readingGuide: 'ຟ + ໄx = ໄຟ'),
        QuizQuestion(questionText: 'ມື', options: [], correctIndex: -1, readingGuide: 'ມ + ື = ມື'),
      ];
    } else if (title.contains('ບົດທີ 6: ອ່ານພະຍັນຊະນະ ຢ, ຣ, ລ, ວ')) {
      questions = [
        QuizQuestion(questionText: 'ຢ', options: [], correctIndex: -1, readingGuide: 'ພະຍັນຊະນະ ຢ (ຢໍ)'),
        QuizQuestion(questionText: 'ຣ', options: [], correctIndex: -1, readingGuide: 'ພະຍັນຊະນະ ຣ (ຣໍ)'),
        QuizQuestion(questionText: 'ລ', options: [], correctIndex: -1, readingGuide: 'ພະຍັນຊະນະ ລ (ລໍ)'),
        QuizQuestion(questionText: 'ວ', options: [], correctIndex: -1, readingGuide: 'ພະຍັນຊະນະ ວ (ວໍ)'),
        QuizQuestion(questionText: 'ຢາ', options: [], correctIndex: -1, readingGuide: 'ຢ + າ = ຢາ'),
        QuizQuestion(questionText: 'ເຮືອ', options: [], correctIndex: -1, readingGuide: 'ຮ + ເxືອ = ເຮືອ'),
        QuizQuestion(questionText: 'ລີ', options: [], correctIndex: -1, readingGuide: 'ລ + ີ = ລີ'),
        QuizQuestion(questionText: 'ເວົ້າ', options: [], correctIndex: -1, readingGuide: 'ວ + ເxົາ + ໄມ້ໂທ = ເວົ້າ'),
      ];
    } else if (title.contains('ບົດທີ 7: ອ່ານພະຍັນຊະນະ ຫ, ອ, ຮ')) {
      questions = [
        QuizQuestion(questionText: 'ຫ', options: [], correctIndex: -1, readingGuide: 'ພະຍັນຊະນະ ຫ (ຫໍ)'),
        QuizQuestion(questionText: 'ອ', options: [], correctIndex: -1, readingGuide: 'ພະຍັນຊະນະ ອ (ອໍ)'),
        QuizQuestion(questionText: 'ຮ', options: [], correctIndex: -1, readingGuide: 'ພະຍັນຊະນະ ຮ (ຮໍ)'),
        QuizQuestion(questionText: 'ຫູ', options: [], correctIndex: -1, readingGuide: 'ຫ + ູ = ຫູ'),
        QuizQuestion(questionText: 'ອ່ານ', options: [], correctIndex: -1, readingGuide: 'ອ + າ + ນ + ໄມ້ເອກ = ອ່ານ'),
        QuizQuestion(questionText: 'ຮາ', options: [], correctIndex: -1, readingGuide: 'ຮ + າ = ຮາ'),
      ];
    } else if (title.contains('ບົດທີ 8: ທວນຄືນອ່ານພະຍັນຊະນະ ກ ຮອດ ຮ')) {
      questions = [
        QuizQuestion(questionText: 'ກ', options: [], correctIndex: -1, readingGuide: 'ກໍ ໄກ່'),
        QuizQuestion(questionText: 'ຂ', options: [], correctIndex: -1, readingGuide: 'ຂໍ ໄຂ່'),
        QuizQuestion(questionText: 'ຄ', options: [], correctIndex: -1, readingGuide: 'ຄໍ ຄວາຍ'),
        QuizQuestion(questionText: 'ງ', options: [], correctIndex: -1, readingGuide: 'ງໍ ງູ'),
        QuizQuestion(questionText: 'ຈ', options: [], correctIndex: -1, readingGuide: 'ຈໍ ຈອກ'),
        QuizQuestion(questionText: 'ສ', options: [], correctIndex: -1, readingGuide: 'ສໍ ເສືອ'),
        QuizQuestion(questionText: 'ຊ', options: [], correctIndex: -1, readingGuide: 'ຊໍ ຊ້າງ'),
        QuizQuestion(questionText: 'ຍ', options: [], correctIndex: -1, readingGuide: 'ຍໍ ຍຸງ'),
        QuizQuestion(questionText: 'ດ', options: [], correctIndex: -1, readingGuide: 'ດໍ ເດັກ'),
        QuizQuestion(questionText: 'ຕ', options: [], correctIndex: -1, readingGuide: 'ຕໍ ຕາ'),
        QuizQuestion(questionText: 'ຖ', options: [], correctIndex: -1, readingGuide: 'ຖໍ ຖົງ'),
        QuizQuestion(questionText: 'ທ', options: [], correctIndex: -1, readingGuide: 'ທໍ ທຸງ'),
        QuizQuestion(questionText: 'ນ', options: [], correctIndex: -1, readingGuide: 'ນໍ ນົກ'),
        QuizQuestion(questionText: 'ບ', options: [], correctIndex: -1, readingGuide: 'ບໍ ແບ້'),
        QuizQuestion(questionText: 'ປ', options: [], correctIndex: -1, readingGuide: 'ປໍ ປາ'),
        QuizQuestion(questionText: 'ຜ', options: [], correctIndex: -1, readingGuide: 'ຜໍ ເຜິ້ງ'),
        QuizQuestion(questionText: 'ຝ', options: [], correctIndex: -1, readingGuide: 'ຝໍ ຝົນ'),
        QuizQuestion(questionText: 'ພ', options: [], correctIndex: -1, readingGuide: 'ພໍ ພູ'),
        QuizQuestion(questionText: 'ຟ', options: [], correctIndex: -1, readingGuide: 'ຟໍ ໄຟ'),
        QuizQuestion(questionText: 'ມ', options: [], correctIndex: -1, readingGuide: 'ມໍ ແມວ'),
        QuizQuestion(questionText: 'ຢ', options: [], correctIndex: -1, readingGuide: 'ຢໍ ຢາ'),
        QuizQuestion(questionText: 'ຣ', options: [], correctIndex: -1, readingGuide: 'ຣໍ ຣົດ'),
        QuizQuestion(questionText: 'ລ', options: [], correctIndex: -1, readingGuide: 'ລໍ ລີງ'),
        QuizQuestion(questionText: 'ວ', options: [], correctIndex: -1, readingGuide: 'ວໍ ວີ'),
        QuizQuestion(questionText: 'ຫ', options: [], correctIndex: -1, readingGuide: 'ຫໍ ຫ່ານ'),
        QuizQuestion(questionText: 'ອ', options: [], correctIndex: -1, readingGuide: 'ອໍ ໂອ'),
        QuizQuestion(questionText: 'ຮ', options: [], correctIndex: -1, readingGuide: 'ຮໍ ເຮືອນ'),
      ];
    } else if (title.contains('ບົດທີ 9: ໂຈດອ່ານສະຫຼະສຽງສັ້ນ xະ, xິ, xຶ, xຸ') || title.contains('ໂຈດອ່ານ 6') || title.contains('ສະຫຼະສຽງສັ້ນ')) {
      questions = [
        QuizQuestion(questionText: 'xະ', options: [], correctIndex: -1, readingGuide: 'ສະຫຼະ xະ (ອະ)'),
        QuizQuestion(questionText: 'xິ', options: [], correctIndex: -1, readingGuide: 'ສະຫຼະ xິ (ອິ)'),
        QuizQuestion(questionText: 'xຶ', options: [], correctIndex: -1, readingGuide: 'ສະຫຼະ xຶ (ອຶ)'),
        QuizQuestion(questionText: 'xຸ', options: [], correctIndex: -1, readingGuide: 'ສະຫຼະ xຸ (ອຸ)'),
        QuizQuestion(questionText: 'ຈະ', options: [], correctIndex: -1, readingGuide: 'ຈ + ະ = ຈະ'),
        QuizQuestion(questionText: 'ກິ', options: [], correctIndex: -1, readingGuide: 'ກ + ິ = ກິ'),
        QuizQuestion(questionText: 'ສຶ', options: [], correctIndex: -1, readingGuide: 'ສ + ຶ = ສຶ'),
        QuizQuestion(questionText: 'ຈຸ', options: [], correctIndex: -1, readingGuide: 'ຈ + ຸ = ຈຸ'),
      ];
    } else if (title.contains('ບົດທີ 10: ໂຈດອ່ານສະຫຼະສຽງຍາວ xາ, xີ, xື, xູ') || title.contains('ໂຈດອ່ານ 7') || title.contains('ສະຫຼະສຽງຍາວ')) {
      questions = [
        QuizQuestion(questionText: 'xາ', options: [], correctIndex: -1, readingGuide: 'ສະຫຼະ xາ (ອາ)'),
        QuizQuestion(questionText: 'xີ', options: [], correctIndex: -1, readingGuide: 'ສະຫຼະ xີ (ອີ)'),
        QuizQuestion(questionText: 'xື', options: [], correctIndex: -1, readingGuide: 'ສະຫຼະ xື (ອື)'),
        QuizQuestion(questionText: 'xູ', options: [], correctIndex: -1, readingGuide: 'ສະຫຼະ xູ (ອູ)'),
        QuizQuestion(questionText: 'ກາ', options: [], correctIndex: -1, readingGuide: 'ກ + າ = ກາ'),
        QuizQuestion(questionText: 'ດີ', options: [], correctIndex: -1, readingGuide: 'ດ + ີ = ດີ'),
        QuizQuestion(questionText: 'ມື', options: [], correctIndex: -1, readingGuide: 'ມ + ື = ມື'),
        QuizQuestion(questionText: 'ປູ', options: [], correctIndex: -1, readingGuide: 'ປ + ູ = ປູ'),
      ];
    } else if (title.contains('ບົດທີ 1: ພະຍັນຊະນະ ກ, ຂ, ຄ, ງ & ສະຫຼະ xະ, xາ')) {
      questions = [
        QuizQuestion(
          questionText: 'ກ + xາ = ? 🐦',
          options: ['ກາ', 'ກະ', 'ກິ', 'ກຶ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຂ + xະ = ? 🌸',
          options: ['ຂາ', 'ຂະ', 'ຂິ', 'ຂຶ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ກາ" 🐦 ປະກອບດ້ວຍພະຍັນຊະນະ ແລະ ສະຫຼະໃດ?',
          options: ['ກ + xະ', 'ກ + xາ', 'ຂ + xະ', 'ຂ + xາ'],
          correctIndex: 1,
        ),
      ];
    } else if (title.contains('ບົດທີ 2: ພະຍັນຊະນະ ຈ, ສ, ຊ, ຍ & ສະຫຼະ xິ, xີ') || title.contains('ບົດທີ 2: ພະຍັນຊະນະ ຈ, ສ, ຊ, ຍ')) {
      questions = [
        QuizQuestion(
          questionText: 'ຈ + xີ = ? 👁️',
          options: ['ຈາ', 'ຈິ', 'ຈີ', 'ຈຶ'],
          correctIndex: 2,
        ),
        QuizQuestion(
          questionText: 'ສ + xິ = ? ✏️',
          options: ['ສາ', 'ສິ', 'ສີ', 'ສຶ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ຊິ" ປະກອບດ້ວຍພະຍັນຊະນະ ແລະ ສະຫຼະໃດ? 🐘',
          options: ['ຊ + xິ', 'ຊ + xີ', 'ຍ + xິ', 'ຍ + xີ'],
          correctIndex: 0,
        ),
      ];
    } else if (title.contains('ບົດທີ 3: ພະຍັນຊະນະ ດ, ຕ, ຖ, ທ & ສະຫຼະ xຶ, xື')) {
      questions = [
        QuizQuestion(
          questionText: 'ດ + xຶ = ? 👶',
          options: ['ດຶ', 'ດື', 'ດິ', 'ດີ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຕ + xື = ? 👁️',
          options: ['ຕຶ', 'ຕື', 'ຕິ', 'ຕີ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ທຶ" ປະກອບດ້ວຍພະຍັນຊະນະ ແລະ ສະຫຼະໃດ? 🚩',
          options: ['ທ + xຶ', 'ທ + xື', 'ຖ + xຶ', 'ຖ + xື'],
          correctIndex: 0,
        ),
      ];
    } else if (title.contains('ບົດທີ 4: ພະຍັນຊະນະ ນ, ບ, ປ, ຜ & ສະຫຼະ xຸ, xູ')) {
      questions = [
        QuizQuestion(
          questionText: 'ປ + xູ = ? 🦀',
          options: ['ປຸ', 'ປູ', 'ຜຸ', 'ຜູ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ນ + xຸ = ? 🐦',
          options: ['ນຸ', 'ນູ', 'ບຸ', 'ບູ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ບູ" ປະກອບດ້ວຍພະຍັນຊະນະ ແລະ ສະຫຼະໃດ? 🐂',
          options: ['ບ + xຸ', 'ບ + xູ', 'ນ + xຸ', 'ນ + xູ'],
          correctIndex: 1,
        ),
      ];
    } else if (title.contains('ບົດທີ 5: ພະຍັນຊະນະ ຝ, ພ, ຟ, ມ & ສະຫຼະ ເx, ແx')) {
      questions = [
        QuizQuestion(
          questionText: 'ມ + ເx = ? 🐈',
          options: ['ເມະ', 'ເມ', 'ແມະ', 'ແມ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຟ + ແx = ? ⚡',
          options: ['ເຟ', 'ແຟ', 'ເຟະ', 'ແຟະ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ເຝ" ປະກອບດ້ວຍພະຍັນຊະນະ ແລະ ສະຫຼະໃດ? 🌧️',
          options: ['ຝ + ເx', 'ຝ + ແx', 'ພ + ເx', 'ພ + ແx'],
          correctIndex: 0,
        ),
      ];
    } else if (title.contains('ບົດທີ 6: ພະຍັນຊະນະ ຢ, ຣ, ລ, ວ & ສະຫຼະ ໂx, xໍ')) {
      questions = [
        QuizQuestion(
          questionText: 'ລ + ໂx = ? 🐒',
          options: ['ໂລະ', 'ໂລ', 'ລໍ', 'ເລະ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ວ + xໍ = ? 🐈',
          options: ['ໂວ', 'ວໍ', 'ໂວະ', 'ແວ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ໂຢ" ປະກອບດ້ວຍພະຍັນຊະນະ ແລະ ສະຫຼະໃດ? 💊',
          options: ['ຢ + ໂx', 'ຢ + ໂxະ', 'ຣ + ໂx', 'ຣ + ໂxະ'],
          correctIndex: 0,
        ),
      ];
    } else if (title.contains('ບົດທີ 7: ພະຍັນຊະນະ ຫ, ອ, ຮ & ສະຫຼະ xຳ, ໄx, ໃx, ເxົາ')) {
      questions = [
        QuizQuestion(
          questionText: 'ຫ + ໃx = ? 📦',
          options: ['ໃຫ', 'ໄຫ', 'ຫຳ', 'ເຫົາ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ອ + ເxົາ = ? 🛁',
          options: ['ອຳ', 'ໄອ', 'ໃອ', 'ເອົາ'],
          correctIndex: 3,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ໄຮ" ປະກອບດ້ວຍພະຍັນຊະນະ ແລະ ສະຫຼະໃດ? 🏠',
          options: ['ຮ + ໄx', 'ຮ + ໃx', 'ຫ + ໄx', 'ຫ + ໃx'],
          correctIndex: 0,
        ),
      ];
    } else if (title.contains('ບົດທີ 8: ทວນຄືນປະສົມພະຍັນຊະນະ ກ ຮອດ ຮ 📚') || title.contains('ບົດທີ 8: ທວນຄືນປະສົມພະຍັນຊະນະ ກ ຮອດ ຮ')) {
      questions = [
        QuizQuestion(
          questionText: 'ກ + xາ = ? 🐦',
          options: ['ກາ', 'ຂາ', 'ຄາ', 'ງາ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຈ + xີ = ? 👁️',
          options: ['ຈິ', 'ຈີ', 'ສິ', 'ສີ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ດ + xີ = ? 👍',
          options: ['ດາ', 'ດີ', 'ຕາ', 'ຕີ'],
          correctIndex: 1,
        ),
      ];
    } else if (title.contains('ບົດທີ 1: ສະຫຼະ xະ, xາ ທີ່ມີຕົວສະກົດ')) {
      questions = [
        QuizQuestion(
          questionText: 'ຄຳໃດແມ່ນການປະສົມຂອງ "ກ + xາ + ງ" ທີ່ຖືກຕ້ອງ? 🌾',
          options: ['ກາ', 'ກາງ', 'ກະ', 'ກັງ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ວັນ" ປະກອບດ້ວຍສະຫຼະ xະ ປ່ຽນຮູບເປັນໄມ້ກັນ (xັ) ແລະ ຕົວສະກົດໃດ? 📅',
          options: ['ຕົວສະກົດ ນ', 'ຕົວສະກົດ ງ', 'ຕົວສະກົດ ກ', 'ຕົວສະກົດ ມ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ສາມ" ປະກອບດ້ວຍຕົວສະກົດໃດ? 🔢',
          options: ['ຕົວສະກົດ ງ', 'ຕົວສະກົດ ມ', 'ຕົວສະກົດ ກ', 'ຕົວສະກົດ ບ'],
          correctIndex: 1,
        ),
      ];
    } else if (title.contains('ບົດທີ 2: ສະຫຼະ xິ, xີ ທີ່ມີຕົວສະກົດ')) {
      questions = [
        QuizQuestion(
          questionText: 'ຄຳໃດແມ່ນການປະສົມຂອງ "ບ + xິ + ງ" ທີ່ຖືກຕ້ອງ? 🔔',
          options: ['ບີ', 'ບິງ', 'ບິວ', 'ບິນ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ປີກ" 🦅 ປະກອບດ້ວຍຕົວສະກົດໃດ?',
          options: ['ຕົວສະກົດ ກ', 'ຕົວສະກົດ ງ', 'ຕົວສະກົດ ຍ', 'ຕົວສະກົດ ດ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ດິນ" ⛰️ ປະກອບດ້ວຍສະຫຼະໃດ?',
          options: ['ສະຫຼະ xີ', 'ສະຫຼະ xິນ', 'ສະຫຼະ xຶ', 'ສະຫຼະ xື'],
          correctIndex: 1,
        ),
      ];
    } else if (title.contains('ບົດທີ 3: ສະຫຼະ xຶ, xື ທີ່ມີຕົວສະກົດ')) {
      questions = [
        QuizQuestion(
          questionText: 'ຄຳໃດແມ່ນການປະສົມຂອງ "ດ + xຶ + ງ" ທີ່ຖືກຕ້ອງ? 🪢',
          options: ['ດຶງ', 'ດືງ', 'ດຶມ', 'ດືມ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ມືດ" 🌑 ປະກອບດ້ວຍຕົວສະກົດໃດ?',
          options: ['ຕົວສະກົດ ງ', 'ຕົວສະກົດ ດ', 'ຕົວສະກົດ ບ', 'ຕົວສະກົດ ກ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ຟຶມ" ປະກອບດ້ວຍສະຫຼະໃດ? 🧵',
          options: ['ສະຫຼະ xື', 'ສະຫຼະ xຶມ', 'ສະຫຼະ xິ', 'ສະຫຼະ xີ'],
          correctIndex: 1,
        ),
      ];
    } else if (title.contains('ບົດທີ 4: ສະຫຼະ xຸ, xູ ທີ່ມີຕົວສະກົດ')) {
      questions = [
        QuizQuestion(
          questionText: 'ຄຳໃດແມ່ນການປະສົມຂອງ "ກ + xຸ + ງ" ທີ່ຖືກຕ້ອງ? 🦐',
          options: ['ກູງ', 'ກຸງ', 'ກຸມ', 'ກູມ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ສູງ" 📈 ປະກອບດ້ວຍຕົວສະກົດໃດ?',
          options: ['ຕົວສະກົດ ງ', 'ຕົວສະກົດ ມ', 'ຕົວສະກົດ ກ', 'ຕົວສະກົດ ດ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ມຸ້ງ" ປະກອບດ້ວຍສະຫຼະໃດ? 🕸️',
          options: ['ສະຫຼະ xູ', 'ສະຫຼະ xຸງ', 'ສະຫຼະ xົ', 'ສະຫຼະ xໍ'],
          correctIndex: 1,
        ),
      ];
    } else if (title.contains('ບົດທີ 5: ທວນຄືນສະຫຼະ xະ, xາ, xິ, xີ, xຶ, xື, xຸ, xູ')) {
      questions = [
        QuizQuestion(
          questionText: 'ຄຳໃດອອກສຽງ "ສະຫຼະ xາ" ທີ່ມີຕົວສະກົດ? 🌾',
          options: ['ຫາ', 'ຫັກ', 'ຫົກ', 'ຫຸກ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ປືນ" 🔫 ປະກອບດ້ວຍພະຍັນຊະນະ ແລະ ສະຫຼະໃດ?',
          options: ['ປ + ສະຫຼະ xິ + ຕົວສະກົດ ນ', 'ປ + ສະຫຼະ xຶ + ຕົວສະກົດ ນ', 'ປ + ສະຫຼະ xື + ຕົວສະກົດ ນ', 'ປ + ສະຫຼະ xີ + ຕົວສະກົດ ນ'],
          correctIndex: 2,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ກຸ້ງ" 🦐 ອອກສຽງສະຫຼະໃດ?',
          options: ['ສະຫຼະ xະ', 'ສະຫຼະ xຸງ', 'ສະຫຼະ xິ', 'ສະຫຼະ xຶ'],
          correctIndex: 1,
        ),
      ];
    } else if (title.contains('ບົດທີ 6: ສະຫຼະ ເxະ, ເx ທີ່ມີຕົວສະກົດ')) {
      questions = [
        QuizQuestion(
          questionText: 'ເມື່ອ ເx + ປ + ຕົວສະກົດ ດ ຈະໄດ້ຄຳໃດ? 🦆',
          options: ['ເປັດ', 'ເປດ', 'ແປດ', 'ເບັດ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ເລກ" 🔢 ໃຊ້ສະຫຼະໃດ?',
          options: ['ສະຫຼະ ແx', 'ສະຫຼະ ເxກ', 'ສະຫຼະ ໂx', 'ສະຫຼະ xໍ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຄຳໃດໃຊ້ "ສະຫຼະ ເx" ທີ່ມີຕົວສະກົດ? 🌲',
          options: ['ເດ', 'ເຮັດ', 'ເສັ້ນ', 'ແກ້ມ'],
          correctIndex: 2,
        ),
      ];
    } else if (title.contains('ບົດທີ 7: ສະຫຼະ ແxະ, ແx ທີ່ມີຕົວສະກົດ')) {
      questions = [
        QuizQuestion(
          questionText: 'ແx + ກ + ຕົວສະກົດ ງ = ? 🔔',
          options: ['ເກງ', 'ແກງ', 'ໂກງ', 'ແກ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ແຂ້ວ" 🦷 ໃຊ້ສະຫຼະໃດ?',
          options: ['ສະຫຼະ ເx', 'ສະຫຼະ ແxວ', 'ສະຫຼະ ໂx', 'ສະຫຼະ xໍ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຄຳໃດສະກົດດ້ວຍ "ສະຫຼະ ແx" ແລະ "ຕົວສະກົດ ດ"? 8️⃣',
          options: ['ເບັດ', 'ແປດ', 'ແກງ', 'ແພ'],
          correctIndex: 1,
        ),
      ];
    } else if (title.contains('ບົດທີ 8: ສະຫຼະ ໂxະ, ໂx ທີ່ມີຕົວສະກົດ')) {
      questions = [
        QuizQuestion(
          questionText: 'ໂx + ນ + ຕົວສະກົດ ນ = ? 🌲',
          options: ['ໂນະ', 'ໂນນ', 'ເນະ', 'ແນນ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ໂຮງ" 🏫 ໃຊ້ສະຫຼະໃດ?',
          options: ['ສະຫຼະ ໂxງ', 'ສະຫຼະ ເx', 'ສະຫຼະ ແx', 'ສະຫຼະ xໍ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ຝົນ" 🌧️ ອອກສຽງສະຫຼະ ໂxະ ຫຼຸດຮູບ ປະກອບດ້ວຍຕົວສະກົດໃດ?',
          options: ['ຕົວສະກົດ ງ', 'ຕົວສະກົດ ນ', 'ຕົວສະກົດ ມ', 'ຕົວສະກົດ ກ'],
          correctIndex: 1,
        ),
      ];
    } else if (title.contains('ບົດທີ 9: ສະຫຼະ ເxາະ, xໍ ທີ່ມີຕົວສະກົດ')) {
      questions = [
        QuizQuestion(
          questionText: 'ແx + ດ + ຕົວສະກົດ ດ = ? 🌸',
          options: ['ເດາະ', 'ດອກ', 'ໂລກ', 'ແດດ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ຮ້ອງ" 🎤 ໃຊ້ສະຫຼະໃດ?',
          options: ['ສະຫຼະ xອງ', 'ສະຫຼະ xໍ', 'ສະຫຼະ ເxາະ', 'ສະຫຼະ ແx'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຄຳໃດໃຊ້ "ສະຫຼະ ເxາະ" ປ່ຽນຮູບເມື່ອມີຕົວສະກົດ? 🐒',
          options: ['ນອກ', 'ບ໋ອກ', 'ຮ້ອງ', 'ຄໍ'],
          correctIndex: 1,
        ),
      ];
    } else if (title.contains('ບົດທີ 10: ທວນຄືນສະຫຼະ ເx, ແx, ໂx, xໍ')) {
      questions = [
        QuizQuestion(
          questionText: 'ຄຳໃດສະກົດດ້ວຍ "ສະຫຼະ ໂx" ແລະ "ຕົວສະກົດ ງ"? 🏫',
          options: ['ແກງ', 'ໂຮງ', 'ຮ້ອງ', 'ເບກ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ແກ້ມ" 😊 ໃຊ້ສະຫຼະໃດ?',
          options: ['ສະຫຼະ ເx', 'ສະຫຼະ ແxມ', 'ສະຫຼະ ໂx', 'ສະຫຼະ xໍ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ສອງ" 2️⃣ ໃຊ້ສະຫຼະໃດ?',
          options: ['ສະຫຼະ xໍ', 'ສະຫຼະ ໂx', 'ສະຫຼະ ເx', 'ສະຫຼະ xອງ'],
          correctIndex: 0,
        ),
      ];
    } else if (title.contains('ບົດທີ 11: ສະຫຼະ ເxິ, ເxີ ທີ່ມີຕົວສະກົດ')) {
      questions = [
        QuizQuestion(
          questionText: 'ເxີ + ດ + ຕົວສະກົດ ນ = ? 🚶',
          options: ['ເດີນ', 'ເດີນ', 'ເດິນ', '`ເດິກ`'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ເງິນ" 💵 ໃຊ້ສະຫຼະໃດ?',
          options: ['ສະຫຼະ ເxິງ', 'ສະຫຼະ ເxີ', 'ສະຫຼະ ເx', 'ສະຫຼະ ແx'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ເບິ່ງ" 👁️ ໃຊ້ສະຫຼະໃດ?',
          options: ['ສະຫຼະ ເxິງ', 'ສະຫຼະ ເxີ', 'ສະຫຼະ xິ', 'ສະຫຼະ xຶ'],
          correctIndex: 0,
        ),
      ];
    } else if (title.contains('ບົດທີ 12: ສະຫຼະ ເxັຍ, ເxຍ ທີ່ມີຕົວສະກົດ')) {
      questions = [
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ຂຽນ" ✍️ ໃຊ້ສະຫຼະໃດ?',
          options: ['ສະຫຼະ ເxຍ', 'ສະຫຼະ xຽນ', 'ສະຫຼະ ເx', 'ສະຫຼະ ແx'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ຮຽນ" 🏫 ປະກອບດ້ວຍພະຍັນຊະນະ ແລະ ສະຫຼະໃດ?',
          options: ['ຮ + ສະຫຼະ ເxຍ + ຕົວສະກົດ ນ', 'ຮ + ສະຫຼະ ເx + ຕົວສະກົດ ນ', 'ຮ + ສະຫຼະ ເxັຍ + ຕົວສະກົດ ນ', 'ຮ + ສະຫຼະ ແx + ຕົວສະກົດ ນ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຄຳໃດສະກົດດ້ວຍ "ສະຫຼະ ເxຍ" ແລະ "ຕົວສະກົດ ວ"? 🟢',
          options: ['ຮຽນ', 'ຂຽວ', 'ປຽກ', 'ບຽດ'],
          correctIndex: 1,
        ),
      ];
    } else if (title.contains('ບົດທີ 13: ສະຫຼະ ເxືອະ, ເxືອ ທີ່ມີຕົວສະກົດ')) {
      questions = [
        QuizQuestion(
          questionText: 'ເxືອ + ລ + ຕົວສະກົດ ກ = ? 🍎',
          options: ['ເລືອກ', 'ເລືອ', 'ເລັກ', 'ແລກ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ເຮືອນ" 🏠 ໃຊ້ສະຫຼະໃດ?',
          options: ['ສະຫຼະ ເxຍ', 'ສະຫຼະ ເxືອ', 'ສະຫຼະ xົວ', 'ສະຫຼະ ເxີ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຄຳໃດສະກົດດ້ວຍ "ສະຫຼະ ເxືອ" ແລະ "ຕົວສະກົດ ງ"? 🟡',
          options: ['ເຮືອນ', 'ເຫຼືອງ', 'ເລືອກ', 'ເກືອ'],
          correctIndex: 1,
        ),
      ];
    } else if (title.contains('ບົດທີ 14: ສະຫຼະ xົວະ, xົວ ທີ່ມີຕົວສະກົດ')) {
      questions = [
        QuizQuestion(
          questionText: 'xົວ + ຫ + ຕົວສະກົດ ຍ = ? 👤',
          options: ['ຫວຍ', 'ຫາງ', 'ຫົວ', 'ຫິວ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ຂວດ" 🍾 ໃຊ້ສະຫຼະໃດ?',
          options: ['ສະຫຼະ xົວ', 'ສະຫຼະ xາ', 'ສະຫຼະ xໍ', 'ສະຫຼະ ໂx'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຄຳໃດສະກົດດ້ວຍ "ສະຫຼະ xົວ" ແລະ "ຕົວສະກົດ ກ"? ➕',
          options: ['ບວກ', 'ຂວດ', 'ຊ່ວຍ', 'ງົວ'],
          correctIndex: 0,
        ),
      ];
    } else if (title.contains('ບົດທີ 15: ທວນຄືນສະຫຼະ ເxີ, ເxຍ, ເxືອ, xົວ')) {
      questions = [
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ຊ່ວຍ" 🤝 ໃຊ້ສະຫຼະໃດ?',
          options: ['ສະຫຼະ ເxືອ', 'ສະຫຼະ xົວ', 'ສະຫຼະ x່ວຍ', 'ສະຫຼະ ເxີ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ເກືອ" 🧂 ໃຊ້ສະຫຼະໃດ?',
          options: ['ສະຫຼະ ເxືອ', 'ສະຫຼະ xົວ', 'ສະຫຼະ ເxຍ', 'ສະຫຼະ ເxີ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ປຽກ" 💦 ໃຊ້ສະຫຼະໃດ?',
          options: ['ສະຫຼະ ເxຍ', 'ສະຫຼະ ເxືອ', 'ສະຫຼະ xົວ', 'ສະຫຼະ xຽກ'],
          correctIndex: 0,
        ),
      ];
    } else if (title.contains('ບົດທີ 16: ພະຍັນຊະນະຄວບ ວ')) {
      questions = [
        QuizQuestion(
          questionText: 'ຄຳໃດມີ "ພະຍັນຊະນະຄວບ ວ"? 🌾',
          options: ['ກວາດ', 'ກາດ', 'ກົດ', 'ແກງ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ຄວາຍ" 🐃 ປະກອບດ້ວຍພະຍັນຊະນະຄວບຕົວໃດ?',
          options: ['ຄວ', 'ຂວ', 'ກວ', 'ປວ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ຂວານ" 🪓 ອ່ານອອກສຽງຄວບຕົວໃດ?',
          options: ['ຂວ', 'ຄວ', 'ຫງ', 'ໜ'],
          correctIndex: 0,
        ),
      ];
    } else if (title.contains('ບົດທີ 17: ອັກສອນຄວບ ແລະ ວັນນະຍຸດ x໋, x໊')) {
      questions = [
        QuizQuestion(
          questionText: 'ເຄື່ອງໝາຍ ໋ ເອີ້ນວ່າວັນນະຍຸດໃດ? 🔔',
          options: ['ໄມ້ຈັດຕະວາ', 'ໄມ້ຕີ', 'ໄມ້ໂທ', 'ໄມ້ເອກ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ເຄື່ອງໝາຍ ໊ ເອີ້ນວ່າວັນນະຍຸດໃດ? 🔔',
          options: ['ໄມ້ຕີ', 'ໄມ້ຈັດຕະວາ', 'ໄມ້ໂທ', 'ໄມ້ເອກ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຄຳໃດໃຊ້ວັນນະຍຸດ "ໄມ້ຈັດຕະວາ" (໋)? 🍜',
          options: ['ກ໋ວຍເຕີ໋ຍວ', 'ກອກ', 'ກ໊ອກ', 'ກ້ອນ'],
          correctIndex: 0,
        ),
      ];
    } else if (title.contains('ບົດທີ 18: ອັກສອນປະສົມ ຫງ, ຫຍ, ໜ, ໝ')) {
      questions = [
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ໜູ" 🐭 ໃຊ້ພະຍັນຊະນະປະສົມຕົວໃດ?',
          options: ['ໜ', 'ໝ', 'ຫງ', 'ຫຍ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ໝວກ" 🎩 ໃຊ້ພະຍັນຊະນະປະສົມຕົວໃດ?',
          options: ['ໝ', 'ໜ', 'ຫຼ', 'ຫວ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ຫຍ້າ" 🌿 ໃຊ້ພະຍັນຊະນະປະສົມຕົວໃດ?',
          options: ['ຫຍ', 'ຫງ', 'ໜ', 'ໝ'],
          correctIndex: 0,
        ),
      ];
    } else if (title.contains('ບົດທີ 19: ອັກສອນປະສົມ ຫຼ, ຫວ ແລະ ຄຳຄຸນນາມ')) {
      questions = [
        QuizQuestion(
          questionText: 'ຄຳໃດແມ່ນ "ຄຳຄຸນນາມ" (ຄຳບອກລັກສະນະ)? 🔴',
          options: ['ແລ່ນ', 'ແດງ', 'ປຶ້ມ', 'ກິນ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ຫຼານ" 👧 ໃຊ້ພະຍັນຊະນະປະສົມຕົວໃດ?',
          options: ['ຫຼ', 'ຫວ', 'ໝ', 'ໜ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ຫວານ" 🍬 ໃຊ້ພະຍັນຊະນະປະສົມຕົວໃດ?',
          options: ['ຫວ', 'ຫຼ', 'ຫຍ', 'ຫງ'],
          correctIndex: 0,
        ),
      ];
    } else if (title.contains('ບົດທີ 20: ທວນຄືນອັກສອນປະສົມ ແລະ ອັກສອນຄວບ')) {
      questions = [
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ກວາງ" 🦌 ຈັດຢູ່ໃນປະເພດໃດ?',
          options: ['ພະຍັນຊະນະຄວບ', 'ອັກສອນປະສົມ', 'ພະຍັນຊະນະດ່ຽວ', 'ບໍ່ມີຂໍ້ຖືກ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ໝາ" 🐶 ຈັດຢູ່ໃນປະເພດໃດ?',
          options: ['ອັກສອນປະສົມ', 'ພະຍັນຊະນະຄວບ', 'ພະຍັນຊະນະດ່ຽວ', 'ບໍ່ມີຂໍ້ຖືກ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຄຳໃດມີພະຍັນຊະນະຄວບ ວ? 🌊',
          options: ['ແກວ່ງ', 'ໜີ', 'ໝູ', 'ຫຼິ້ນ'],
          correctIndex: 0,
        ),
      ];
    } else if (title.contains('ບົດທີ 21: ຄຳນາມ ແລະ ຄຳກຳມະ')) {
      questions = [
        QuizQuestion(
          questionText: 'ຄຳໃດແມ່ນ "ຄຳນາມ" (ຊື່ເອີ້ນສິ່ງຂອງ/ຄົນ/ສັດ)? 🎒',
          options: ['ແລ່ນ', 'ປຶ້ມ', 'ກິນ', 'ນອນ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຄຳໃດແມ່ນ "ຄຳກຳມະ" (ຄຳບອກການກະທຳ)? 🏃',
          options: ['ແລ່ນ', 'ໂຕະ', 'ແມວ', 'ງາມ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ໃນປະໂຫຍກ "ແມວ ກິນ ປາ" ຄຳໃດແມ່ນຄຳກຳມະ? 🐱🐟',
          options: ['ແມວ', 'ກິນ', 'ປາ', 'ບໍ່ມີຄຳກຳມະ'],
          correctIndex: 1,
        ),
      ];
    } else if (title.contains('ບົດທີ 22: ຄຳແທນນາມ ແລະ ປະໂຫຍກ')) {
      questions = [
        QuizQuestion(
          questionText: 'ຄຳໃດແມ່ນ "ຄຳແທນນາມ" (ຄຳໃຊ້ແທນຊື່)? 👤',
          options: ['ຂ້ອຍ', 'ໂຮງຮຽນ', 'ແລ່ນ', 'ໃຫຍ່'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຄຳແທນນາມທີ່ໃຊ້ເວົ້າແທນຜູ້ທີ່ເຮົາກຳລັງເວົ້າດ້ວຍແມ່ນຄຳໃດ? 🤝',
          options: ['ຂ້ອຍ', 'ເຈົ້າ', 'ລາວ', 'ພວກເຂົາ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ປະໂຫຍກໃດມີຄຳແທນນາມ? 💬',
          options: ['ຂ້ອຍໄປໂຮງຮຽນ', 'ແມວແລ່ນໄວ', 'ດອກໄມ້ງາມ', 'ພໍ່ເຮັດວຽກ'],
          correctIndex: 0,
        ),
      ];
    } else if (title.contains('ບົດທີ 23: ຄຳເຊື່ອມ ແລະ ເຄື່ອງໝາຍຈຸດ')) {
      questions = [
        QuizQuestion(
          questionText: 'ຄຳໃດແມ່ນ "ຄຳເຊື່ອມ" (ຄຳເຊື່ອມໂຍງຄຳ)? 🔗',
          options: ['ແລະ', 'ແມວ', 'ແລ່ນ', 'ງາມ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ເຄື່ອງໝາຍຈຸດ (,) ໃຊ້ເພື່ອຫຍັງ? ✍️',
          options: ['ໝາຍບອກໃຫ້ຈົບປະໂຫຍກ', 'ໝາຍແຍກຄຳສັບ ຫຼື ຂໍ້ຄວາມ', 'ໝາຍຖາມ', 'ໝາຍຕົກໃຈ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ແຕ່" ໃນປະໂຫຍກ "ລາວຮຽນເກັ່ງ ແຕ່ ຂີ້ຄ້ານ" ແມ່ນຄຳປະເພດໃດ? 🔗',
          options: ['ຄຳເຊື່ອມ', 'ຄຳນາມ', 'ຄຳກຳມະ', 'ຄຳຄຸນນາມ'],
          correctIndex: 0,
        ),
      ];
    } else if (title.contains('ບົດທີ 24: ເຄື່ອງໝາຍອັດສະຈັນ (!) ແລະ ເຄື່ອງໝາຍຖາມ (?)')) {
      questions = [
        QuizQuestion(
          questionText: 'ເຄື່ອງໝາຍອັດສະຈັນ (!) ໃຊ້ສະແດງຄວາມຮູ້ສຶກໃດ? 💥',
          options: ['ຖາມຄຳຖາມ', 'ຕົກໃຈ ຫຼື ຕື່ນເຕັ້ນ', 'ບອກໃຫ້ຢຸດ', 'ບໍ່ມີຄວາມຮູ້ສຶກ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ເຄື່ອງໝາຍຖາມ (?) ໃຊ້ຕິດທ້າຍປະໂຫຍກປະເພດໃດ? ❓',
          options: ['ປະໂຫຍກຄຳຖາມ', 'ປະໂຫຍກບອກເລົ່າ', 'ປະໂຫຍກປະຕіເສດ', 'ປະໂຫຍກຄຳສັ່ງ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຄຳອຸທານ "ໂອ້ໂຮ!" ຄວນໃຊ້ເຄື່ອງໝາຍວັກຕອນໃດທ້າຍຄຳ? 💥',
          options: ['ເຄື່ອງໝາຍອັດສະຈັນ (!)', 'ເຄື່ອງໝາຍຖາມ (?)', 'ເຄື່ອງໝາຍຈຸດ (,)', 'ເຄື່ອງໝາຍມຸດ'],
          correctIndex: 0,
        ),
      ];
    } else if (title.contains('ບົດທີ 25: ທວນຄືນປະເພດຄຳ ແລະ ເຄື່ອງໝາຍວັກຕອນ')) {
      questions = [
        QuizQuestion(
          questionText: 'ຄຳໃດແມ່ນຄຳນາມ? 🐶',
          options: ['ໝາ', 'ຮ້ອງ', 'ແລະ', 'ໄວ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ປະໂຫຍກ "ເຈົ້າຊື່ຫຍັງ..." ຄວນຕື່ມເຄື່ອງໝາຍໃດ? ❓',
          options: ['ເຄື່ອງໝາຍຖາມ (?)', 'ເຄື່ອງໝາຍອັດສະຈັນ (!)', 'ເຄື່ອງໝາຍຈຸດ (,)', 'ບໍ່ຕ້ອງຕື່ມ'], // ເຄື່ອງໝາຍຖາມ
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຄຳໃດແມ່ນຄຳກຳມະ? 📖',
          options: ['ອ່ານ', 'ປຶ້ມ', 'ດີ', 'ພວກເຮົາ'],
          correctIndex: 0,
        ),
      ];
    } else if (title.contains('ບົດທີ 26: ການຂຽນຈົດໝາຍ ແລະ ບົດເລົ່າຄືນ')) {
      questions = [
        QuizQuestion(
          questionText: 'ເມື່ອຂຽນຈົດໝາຍຫາໝູ່, ຄຳຂຶ້ນຕົ້ນຄວນໃຊ້ຄຳໃດ? ✉️',
          options: ['ຮຽນ...', 'ຮັກແພງ...', 'ຮຽນທ່ານ...', 'ສະບາຍດີທ່ານ...'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ບົດເລົ່າຄືນ ແມ່ນການຂຽນກ່ຽວກັບຫຍັງ? 📖',
          options: ['ເລົ່າເຫດການທີ່ຜ່ານມາແລ້ວ', 'ບອກວິທີເຮັດອາຫານ', 'ແຕ່ງເລື່ອງໃນອະນາຄົດ', 'ບໍ່ມີຂໍ້ຖືກ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ສ່ວນປະກອບໃດທີ່ຕ້ອງມີໃນການຈົດໝາຍຫາຜູ້ອື່ນ? ✉️',
          options: ['ຊື່ຜູ້ຮັບ ແລະ ຜູ້ສົ່ງ', 'ສູດຄິດໄລ່ເລກ', 'ຮູບແຕ້ມກາຕູນ', 'ບໍ່ມີຂໍ້ຖືກ'],
          correctIndex: 0,
        ),
      ];
    } else if (title.contains('ບົດທີ 27: ການຂຽນບົດອະທິບາຍ ແລະ ວິທີການ') || title.contains('ບົດທີ 27: ການຂຽນບົດອະທິບາຍ')) {
      questions = [
        QuizQuestion(
          questionText: 'ບົດອະທິບາຍ ຫຼື ບົດວິທີການ ຂຽນຂຶ້ນມາເພື່ອຫຍັງ? 📝',
          options: ['ບອກຂັ້ນຕອນການເຮັດສິ່ງໃດໜຶ່ງ', 'ເລົ່ານິທານໃຫ້ຟັງ', 'ສະແດງຄວາມດີໃຈ', 'ສົ່ງຫາໝູ່'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ການຂຽນວິທີລ້າງມືໃຫ້ສະອາດ ຈັດຢູ່ໃນບົດປະເພດໃດ? 🧼',
          options: ['ບົດອະທິບາຍວິທີການ', 'ບົດເລົ່າຄືນ', 'ບົດສະແດງຄວາມຄິດເຫັນ', 'ຈົດໝາຍ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ໃນບົດວິທີການ ຄວນຈັດລຽງຂັ້ນຕອນແນວໃດ? 📝',
          options: ['ລຽງຕາມລຳດັບກ່ອນ ແລະ ຫຼັງ', 'ລຽງຕາມຄວາມຊອບໃຈ', 'ບໍ່ຕ້ອງລຽງລຳດັບ', 'ລຽງຈາກຫຼັງມາໜ້າ'],
          correctIndex: 0,
        ),
      ];
    } else if (title.contains('ບົດທີ 28: ການຂຽນບົດສະແດງຄວາມຄິດເຫັນ')) {
      questions = [
        QuizQuestion(
          questionText: 'ບົດສະແດງຄວາມຄິດເຫັນ ຄວນປະກອບດ້ວຍຫຍັງຫຼັກໆ? ✍️',
          options: ['ເຫດຜົນສະໜັບສະໜູນ', 'ຂັ້ນຕອນການທົດລອງ', 'ບົດກອນຍາວໆ', 'ສູດຄະນິດສາດ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຄຳໃດມັກໃຊ້ໃນການຂຶ້ນຕົ້ນບົດສະແດງຄວາມຄິດເຫັນ? ✍️',
          options: ['ຂ້ອຍຄິດວ່າ...', 'ຂັ້ນຕອນທີ 1...', 'ຮັກແພງ...', 'ມື້ໜຶ່ງ...'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ການຂຽນບອກວ່າ "ເປັນຫຍັງພວກເຮົາຄວນຮັກສາຄວາມສະອາດ" ແມ່ນບົດປະເພດໃດ? 🧹',
          options: ['ບົດສະແດງຄວາມຄິດເຫັນ', 'ບົດເລົ່າຄືນ', 'ຈົດໝາຍ', 'ບົດວິທີການ'],
          correctIndex: 0,
        ),
      ];
    } else if (title.contains('ບົດທີ 29: ການອ່ານກາບກອນ ແລະ ນິທານ')) {
      questions = [
        QuizQuestion(
          questionText: 'ກາບກອນ ມີລັກສະນະເດັ່ນແນວໃດ? 🎶',
          options: ['ມີຄຳສຳຜັດເກາະກ່າຍກັນ', 'ຂຽນຍາວໆບໍ່ມີວັກ', 'ມີແຕ່ຕົວເລກ', 'ບໍ່ມີຈັງຫວະ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ນິທານ ໃຫ້ປະໂຫຍດຫຍັງແກ່ເດັກນ້ອຍ? 📖',
          options: ['ໃຫ້ຄວາມມ່ວນຊື່ນ ແລະ ຂໍ້ຄິດເຕືອນໃຈ', 'ໃຫ້ວິທີແກ້ເລກ', 'ໃຫ້ຄວາມຮູ້ວິທະຍາສາດເລິກເຊິ່ງ', 'ບໍ່ມີປະໂຫຍດ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຄຳວ່າ "ກາ" ກັບ "ຂາ" ໃນກາບກອນ ເອີ້ນວ່າຄຳຫຍັງ? 🎶',
          options: ['ຄຳສຳຜັດສຽງ', 'ຄຳກຳມະ', 'ຄຳແທນນາມ', 'ຄຳເຊື່ອມ'],
          correctIndex: 0,
        ),
      ];
    } else if (title.contains('ບົດທີ 30: ທວນຄືນຄວາມຮູ້ພາສາລາວທ້າຍປີ')) {
      questions = [
        QuizQuestion(
          questionText: 'ຄຳໃດສະກົດດ້ວຍ ຕົວສະກົດ ງ? 🔔',
          options: ['ແກງ', 'ຮຽນ', 'ບາດ', 'ອາບ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຄຳໃດແມ່ນຄຳຄຸນນາມບອກລັກສະນະສີ? 🟢',
          options: ['ຂຽວ', 'ແລ່ນ', 'ໂຕະ', 'ຂ້ອຍ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ເຄື່ອງໝາຍວັກຕອນໃດໃຊ້ຖາມຄຳຖາມ? ❓',
          options: ['ເຄື່ອງໝາຍຖາມ (?)', 'ເຄື່ອງໝາຍອັດສະຈັນ (!)', 'ເຄື່ອງໝາຍຈຸດ (,)', 'ເຄື່ອງໝາຍມຸດ'],
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
        QuizQuestion(questionText: 'ອັກສອນກາງທັງໝົດ ມີຈັກຕົວ?', options: ['5 ຕົວ', '7 ຕົວ', '9 ຕົວ', '6 ຕົວ'], correctIndex: 1),
        QuizQuestion(questionText: 'ຕົວໃດ ເປັນ ອັກສອນກາງ?', options: ['ຄ', 'ງ', 'ກ', 'ສ'], correctIndex: 2),
        QuizQuestion(questionText: 'ກ ຈ ດ ຕ ບ ປ ອ ຢູ່ໃນໝວດໃດ?', options: ['ໝວດຕໍ່າ', 'ໝວດກາງ', 'ໝວດສູງ', 'ໝວດພິເສດ'], correctIndex: 1),
        QuizQuestion(questionText: 'ຕົວ ຕ ຢູ່ໃນໝວດໃດ?', options: ['ໝວດຕໍ່າ', 'ໝວດສູງ', 'ໝວດກາງ', 'ໝວດພິເສດ'], correctIndex: 2),
        QuizQuestion(questionText: 'ຕົວໃດ ບໍ່ແມ່ນ ອັກສອນກາງ?', options: ['ດ', 'ຕ', 'ສ', 'ອ'], correctIndex: 2),
      ];
    } else if (title.contains('ໂຈດອ່ານ 2') || title.contains('ອັກສອນສູງ ຂ ສ')) {
      questions = [
        QuizQuestion(questionText: 'ອັກສອນສູງທັງໝົດ ມີຈັກຕົວ?', options: ['3 ຕົວ', '4 ຕົວ', '5 ຕົວ', '6 ຕົວ'], correctIndex: 2),
        QuizQuestion(questionText: 'ຕົວໃດ ເປັນ ອັກສອນສູງ?', options: ['ຄ', 'ຂ', 'ກ', 'ຊ'], correctIndex: 1),
        QuizQuestion(questionText: 'ຂ ສ ຖ ຝ ຫ ຢູ່ໃນໝວດໃດ?', options: ['ໝວດຕໍ່າ', 'ໝວດກາງ', 'ໝວດສູງ', 'ໝວດພິເສດ'], correctIndex: 2),
        QuizQuestion(questionText: 'ຕົວໃດ ເປັນ ອັກສອນສູງ?', options: ['ທ', 'ໜ', 'ຝ', 'ຟ'], correctIndex: 2),
        QuizQuestion(questionText: 'ອັກສອນ ຫ ຢູ່ໃນໝວດໃດ?', options: ['ໝວດຕໍ່າ', 'ໝວດກາງ', 'ໝວດສູງ', 'ໝວດພິເສດ'], correctIndex: 2),
      ];
    } else if (title.contains('ໂຈດອ່ານ 3') || title.contains('ອັກສອນຕໍ່າ ຄ ງ ຊ')) {
      questions = [
        QuizQuestion(questionText: 'ຕົວໃດ ເປັນ ອັກສອນຕໍ່າ?', options: ['ກ', 'ຄ', 'ຂ', 'ຈ'], correctIndex: 1),
        QuizQuestion(questionText: 'ຄ ງ ຊ ຍ ທ ນ ຢູ່ໃນໝວດໃດ?', options: ['ໝວດກາງ', 'ໝວດສູງ', 'ໝວດຕໍ່າ', 'ໝວດພິເສດ'], correctIndex: 2),
        QuizQuestion(questionText: 'ຕົວ ງ + ູ ໄດ້ຄຳ...?', options: ['ງູ', 'ຄູ', 'ນູ', 'ຊູ'], correctIndex: 0),
        QuizQuestion(questionText: 'ຕົວໃດ ເປັນ ອັກສອນຕໍ່າ?', options: ['ດ', 'ຖ', 'ຍ', 'ຕ'], correctIndex: 2),
        QuizQuestion(questionText: 'ຕົວ ທ ຢູ່ໃນໝວດໃດ?', options: ['ໝວດກາງ', 'ໝວດຕໍ່າ', 'ໝວດສູງ', 'ໝວດພິເສດ'], correctIndex: 1),
      ];
    } else if (title.contains('ໂຈດອ່ານ 4') || title.contains('ອັກສອນຕໍ່າ ຜ ພ')) {
      questions = [
        QuizQuestion(questionText: 'ຕົວ ຮ ຢູ່ໃນໝວດໃດ?', options: ['ໝວດສູງ', 'ໝວດກາງ', 'ໝວດຕໍ່າ', 'ໝວດພິເສດ'], correctIndex: 2),
        QuizQuestion(questionText: 'ຕົວໃດ ເປັນ ອັກສອນຕໍ່າ?', options: ['ສ', 'ຫ', 'ຖ', 'ມ'], correctIndex: 3),
        QuizQuestion(questionText: 'ຕົວ ຜ ຢູ່ໃນໝວດໃດ?', options: ['ໝວດສູງ', 'ໝວດກາງ', 'ໝວດຕໍ່າ', 'ໝວດພິເສດ'], correctIndex: 2),
        QuizQuestion(questionText: 'ຕົວໃດ ບໍ່ແມ່ນ ອັກສອນຕໍ່າ?', options: ['ລ', 'ວ', 'ສ', 'ຟ'], correctIndex: 2),
        QuizQuestion(questionText: 'ຄຳ ຮຽນ ໃຊ້ອັກສອນໝວດໃດ?', options: ['ຮ (ໝວດຕໍ່າ)', 'ຫ (ໝວດສູງ)', 'ຮ (ໝວດສູງ)', 'ຫ (ໝວດຕໍ່າ)'], correctIndex: 0),
      ];
    } else if (title.contains('ໂຈດອ່ານ 5') || title.contains('ອັກສອນປະສົມ ຫງ')) {
      questions = [
        QuizQuestion(questionText: 'ໝາ ໃຊ້ອັກສອນປະສົມໃດ?', options: ['ຫງ', 'ຫຍ', 'ໝ (ຫ+ມ)', 'ໜ (ຫ+ນ)'], correctIndex: 2),
        QuizQuestion(questionText: 'ອັກສອນ ໜ ປະກອບດ້ວຍ...?', options: ['ຫ+ງ', 'ຫ+ຍ', 'ຫ+ນ', 'ຫ+ລ'], correctIndex: 2),
        QuizQuestion(questionText: 'ຫຼານ ໃຊ້ອັກສອນປະສົມໃດ?', options: ['ຫງ', 'ຫຼ', 'ຫຍ', 'ຫວ'], correctIndex: 1),
        QuizQuestion(questionText: 'ຄຳ ຫງ ອ່ານສຽງ...?', options: ['ງ ສຽງຕໍ່າ', 'ງ ສຽງສູງ', 'ຫ ສຽງຕໍ່າ', 'ຫ ສຽງກາງ'], correctIndex: 1),
        QuizQuestion(questionText: 'ຫວານ ໃຊ້ອັກສອນປະສົມໃດ?', options: ['ຫງ', 'ຫຍ', 'ໜ', 'ຫວ'], correctIndex: 3),
      ];
    } else if (title.contains('ໂຈດອ່ານ 6') || title.contains('ສະຫຼະສຽງສັ້ນ')) {
      questions = [
        QuizQuestion(questionText: 'xະ + ກ ໄດ້ຄຳ...?', options: ['ກາ', 'ກະ', 'ກິ', 'ກຶ'], correctIndex: 1),
        QuizQuestion(questionText: 'ສະຫຼະ xິ ອອກສຽງ...?', options: ['ອາ ສັ້ນ', 'ອິ ສັ້ນ', 'ອຶ ສັ້ນ', 'ອຸ ສັ້ນ'], correctIndex: 1),
        QuizQuestion(questionText: 'ຄຳ ຈຸ ໃຊ້ສະຫຼະໃດ?', options: ['xະ', 'xິ', 'xຶ', 'xຸ'], correctIndex: 3),
        QuizQuestion(questionText: 'xຶ + ສ ໄດ້ຄຳ...?', options: ['ສິ', 'ສຸ', 'ສຶ', 'ສາ'], correctIndex: 2),
        QuizQuestion(questionText: 'ສະຫຼະໃດ ອອກສຽງ ອຶ ສັ້ນ?', options: ['xະ', 'xິ', 'xຶ', 'xຸ'], correctIndex: 2),
      ];
    } else if (title.contains('ໂຈດອ່ານ 7') || title.contains('ສະຫຼະສຽງຍາວ')) {
      questions = [
        QuizQuestion(questionText: 'ກາ ໃຊ້ສະຫຼະໃດ?', options: ['xີ', 'xາ', 'xື', 'xູ'], correctIndex: 1),
        QuizQuestion(questionText: 'xີ + ດ ໄດ້ຄຳ...?', options: ['ດາ', 'ດີ', 'ດື', 'ດູ'], correctIndex: 1),
        QuizQuestion(questionText: 'ມື ໃຊ້ສະຫຼະໃດ?', options: ['xາ', 'xີ', 'xື', 'xູ'], correctIndex: 2),
        QuizQuestion(questionText: 'xູ + ຈ ໄດ້ຄຳ...?', options: ['ຈາ', 'ຈີ', 'ຈື', 'ຈູ'], correctIndex: 3),
        QuizQuestion(questionText: 'ສະຫຼະ xາ ໝາຍເຖິງ...?', options: ['ອາ ສັ້ນ', 'ອາ ຍາວ', 'ອີ ຍາວ', 'ອຶ ຍາວ'], correctIndex: 1),
      ];
    } else if (title.contains('ໂຈດອ່ານ 8') || title.contains('ສະຫຼະ ເx ແx')) {
      questions = [
        QuizQuestion(questionText: 'ແx + ກ ໄດ້ຄຳ...?', options: ['ເກ', 'ແກ', 'ໂກ', 'ກໍ'], correctIndex: 1),
        QuizQuestion(questionText: 'ໂນ ໃຊ້ສະຫຼະໃດ?', options: ['ເx', 'ແx', 'ໂx', 'xໍ'], correctIndex: 2),
        QuizQuestion(questionText: 'xໍ + ປ ໄດ້ຄຳ...?', options: ['ເປ', 'ແປ', 'ໂປ', 'ປໍ'], correctIndex: 3),
        QuizQuestion(questionText: 'ແທ ໃຊ້ສະຫຼະໃດ?', options: ['ເx', 'ແx', 'ໂx', 'xໍ'], correctIndex: 1),
        QuizQuestion(questionText: 'ເດ ໃຊ້ສະຫຼະໃດ?', options: ['ແx', 'ເx', 'ໂx', 'xໍ'], correctIndex: 1),
      ];
    } else if (title.contains('ບົດທີ 1: ການນຳສະເໜີຂໍ້ມູນ ແລະ ຕາຕະລາງ')) {
      questions = [
        QuizQuestion(
          questionText: 'ຈາກຕາຕະລາງສັດລ້ຽງ: ແມວມີ 5 ໂຕ, ໝາມີ 3 ໂຕ. ມີສັດລ້ຽງທັງໝົດຈັກໂຕ? 🐱🐶',
          options: ['7 ໂຕ', '8 ໂຕ', '9 ໂຕ', '10 ໂຕ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ໃນຫ້ອງຮຽນມີ ປຶ້ມຂຽນ 6 ຫົວ, ສໍດຳ 4 ກ້ານ. ປຶ້ມຂຽນຫຼາຍກວ່າສໍດຳຈັກຫົວ/ກ້ານ? 📚✏️',
          options: ['1 ຫົວ', '2 ຫົວ', '3 ຫົວ', '4 ຫົວ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຈາກຕາຕະລາງໝາກໄມ້: ໝາກກ້ວຍ 7 ໜ່ວຍ, ໝາກມ່ວງ 4 ໜ່ວຍ. ໝາກໄມ້ຊະນິດໃດມີໜ້ອຍກວ່າ? 🍌🥭',
          options: ['ໝາກກ້ວຍ 🍌', 'ໝາກມ່ວງ 🥭', 'ເທົ່າກັນ', 'ບໍ່ມີຂໍ້ຖືກ'],
          correctIndex: 1,
        ),
      ];
    } else if (title.contains('ບົດທີ 2: จຳນວນທີ່ມີສາມຕົວເລກ') || title.contains('ບົດທີ 2: ຈຳນວນທີ່ມີສາມຕົວເລກ')) {
      questions = [
        QuizQuestion(
          questionText: 'ຈຳນວນທີ່ປະກອບດ້ວຍ 2 ຮ້ອຍ ກັບ 4 ສິບ ກັບ 7 ໜ່ວຍ ແມ່ນຈຳນວນໃດ? 🔢',
          options: ['247', '274', '427', '742'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ເລກ 305 ຂຽນແຍກຕາມຫຼັກຈຳນວນໄດ້ແນວໃດ? 🧮',
          options: ['30 + 5', '300 + 5', '300 + 50', '3 + 0 + 5'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ໃນເລກ 862, ຕົວເລກໃດຢູ່ໃນຫຼັກຮ້ອຍ? 🌟',
          options: ['2', '6', '8', '0'],
          correctIndex: 2,
        ),
      ];
    } else if (title.contains('ບົດທີ 3: ການບວກເລກສອງຫຼັກ')) {
      questions = [
        QuizQuestion(
          questionText: '38 + 25 = ? ➕',
          options: ['53', '63', '58', '60'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: '47 + 16 = ? 🧮',
          options: ['53', '63', '57', '61'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຖ້າມີໝາກກ້ຽງ 29 ໜ່ວຍ ແລະ ໄດ້ຕື່ມອີກ 15 ໜ່ວຍ. ຈະມີໝາກກ້ຽງທັງໝົດຈັກໜ່ວຍ? 🍊',
          options: ['34 ໜ່ວຍ', '44 ໜ່ວຍ', '45 ໜ່ວຍ', '39 ໜ່ວຍ'],
          correctIndex: 1,
        ),
      ];
    } else if (title.contains('ບົດທີ 4: ການລົບເລກສອງຫຼັກ')) {
      questions = [
        QuizQuestion(
          questionText: '52 - 28 = ? ➖',
          options: ['24', '34', '26', '36'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: '70 - 45 = ? 🧮',
          options: ['35', '25', '30', '15'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ມີເຂົ້າໜົມ 41 ກ້ອນ, ແບ່ງໃຫ້ໝູ່ 17 ກ້ອນ. ຈະເຫຼືອເຂົ້າໜົມຈັກກ້ອນ? 🍬',
          options: ['24 ກ້ອນ', '34 ກ້ອນ', '26 ກ້ອນ', '14 ກ້ອນ'],
          correctIndex: 0,
        ),
      ];
    } else if (title.contains('ບົດທີ 5: ຮູບເລຂາຄະນິດ')) {
      questions = [
        QuizQuestion(
          questionText: 'ຮູບສາມແຈ ມີມູມທັງໝົດຈັກມູມ? 📐',
          options: ['2 ມູມ', '3 ມູມ', '4 ມູມ', '5 ມູມ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຮູບທີ່ມີ 4 ຂ້າງ ແລະ 4 ມູມສາກ ແມ່ນຮູບໃດ? 📐',
          options: ['ຮູບສາມແຈ', 'ຮູບວົງມົນ', 'ຮູບສີ່ແຈສາກ', 'ຮູບຫ້າແຈ'],
          correctIndex: 2,
        ),
        QuizQuestion(
          questionText: 'ເສັ້ນຊື່ສອງເສັ້ນທີ່ຕັດກັນແລ້ວເກີດເປັນມູມ 90 ອົງສາ ເອີ້ນວ່າມູມໃດ? 📐',
          options: ['ມູມແຫຼມ', 'ມູມຫວາກ', 'ມູມສາກ', 'ມູມພຽງ'],
          correctIndex: 2,
        ),
      ];
    } else if (title.contains('ບົດທີ 6: ຄວາມຍາວ ແລະ ການວັດແທກ')) {
      questions = [
        QuizQuestion(
          questionText: '1 ແມັດ (ມ) ເທົ່າກັບຈັກ ຊັງຕີແມັດ (ຊມ)? 📏',
          options: ['10 ຊມ', '100 ຊມ', '1000 ຊມ', '50 ຊມ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: '1 ຊັງຕີແມັດ (ຊມ) ເທົ່າກັບຈັກ ມິນລີແມັດ (ມມ)? 📏',
          options: ['10 ມມ', '100 ມມ', '5 ມມ', '20 ມມ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຖ້າໄມ້ບັນທັດຍາວ 30 ຊມ. ໄມ້ບັນທັດ 2 ອັນຕໍ່ກັນຈະຍາວຈັກ ຊມ? 📏',
          options: ['50 ຊມ', '60 ຊມ', '90 ຊມ', '40 ຊມ'],
          correctIndex: 1,
        ),
      ];
    } else if (title.contains('ບົດທີ 7: ການຄູນ ແລະ ຕາຕະລາງບັ້ງສູດ')) {
      questions = [
        QuizQuestion(
          questionText: '5 x 4 = ? ✖️',
          options: ['15', '20', '25', '30'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: '2 x 8 = ? 🧮',
          options: ['14', '16', '18', '20'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: '10 x 6 = ? 💵',
          options: ['50', '60', '70', '100'],
          correctIndex: 1,
        ),
      ];
    } else if (title.contains('ບົດທີ 8: ການຫານ')) {
      questions = [
        QuizQuestion(
          questionText: 'ມີເຂົ້າໜົມ 10 ກ້ອນ, ແບ່ງໃຫ້ເດັກ 2 ຄົນເທົ່າໆກັນ. ແຕ່ລະຄົນຈະໄດ້ຈັກກ້ອນ? 🍬',
          options: ['4 ກ້ອນ', '5 ກ້ອນ', '6 ກ້ອນ', '2 ກ້ອນ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: '15 ➗ 3 = ? ➗',
          options: ['3', '4', '5', '6'],
          correctIndex: 2,
        ),
        QuizQuestion(
          questionText: '20 ➗ 5 = ? 🧮',
          options: ['4', '5', '10', '15'],
          correctIndex: 0,
        ),
      ];
    } else if (title.contains('ບົດທີ 9: ໂຈດບັນຫາການບວກ ແລະ ການລົບ') && grade == 'P2') {
      questions = [
        QuizQuestion(
          questionText: 'ມີເງິນ 80 ກີບ, ຊື້ເຂົ້າໜົມ 35 ກີບ. ຈະເຫຼືອເງິນຈັກກີບ? 💵',
          options: ['45 ກີບ', '55 ກີບ', '40 ກີບ', '50 ກີບ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ທ້າວແດງມີສໍດຳ 14 ກ້ານ, ນາງດຳມີສໍດຳຫຼາຍກວ່າທ້າວແດງ 8 ກ້ານ. ນາງດຳມີສໍດຳຈັກກ້ານ? ✏️',
          options: ['20 ກ້ານ', '22 ກ້ານ', '24 ກ້ານ', '18 ກ້ານ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ໃນຫ້ອງຮຽນມີນັກຮຽນຍິງ 18 ຄົນ ແລະ ນັກຮຽນຊາຍ 15 ຄົນ. ໃນຫ້ອງຮຽນມີນັກຮຽນທັງໝົດຈັກຄົນ? 🏫',
          options: ['30 ຄົນ', '33 ຄົນ', '35 ຄົນ', '28 ຄົນ'],
          correctIndex: 1,
        ),
      ];
    } else if (title.contains('ບົດທີ 10: ໂມງ ແລະ ເວລາ') && grade == 'P2') {
      questions = [
        QuizQuestion(
          questionText: 'ເຂັມສັ້ນຊີ້ໃສ່ເລກ 9, ເຂັມຍາວຊີ້ໃສ່ເລກ 12. ແມ່ນເວລາຈັກໂມງ? ⏰',
          options: ['8 ໂມງ', '9 ໂມງ', '10 ໂມງ', '12 ໂມງ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: '1 ຊົ່ວໂມງ ມີຈັກນາທີ? ⏰',
          options: ['30 ນາທີ', '50 ນາທີ', '60 ນາທີ', '100 ນາທີ'],
          correctIndex: 2,
        ),
        QuizQuestion(
          questionText: 'ຖ້າຕອນນີ້ແມ່ນ 8:00 ໂມງ, ອີກ 2 ຊົ່ວໂມງຕໍ່ມາຈະແມ່ນເວລາຈັກໂມງ? ⏰',
          options: ['9:00 ໂມງ', '10:00 ໂມງ', '11:00 ໂມງ', '12:00 ໂມງ'],
          correctIndex: 1,
        ),
      ];
    } else if (title.contains('ບົດທີ 11: ປະລິມານນ້ຳ ແລະ ຄວາມບັນຈຸ') && grade == 'P2') {
      questions = [
        QuizQuestion(
          questionText: '1 ລິດ (ລ) ເທົ່າກັບຈັກ ມິນລີລິດ (ມລ)? 🍼',
          options: ['100 ມລ', '500 ມລ', '1000 ມລ', '2000 ມລ'],
          correctIndex: 2,
        ),
        QuizQuestion(
          questionText: 'ຖ້າມີນ້ຳຢູ່ 2 ຕຸກ, ຕຸກລະ 1 ລິດ ແລະ 500 ມລ. ປະລິມານນ້ຳທັງໝົດແມ່ນເທົ່າໃດ? 💧',
          options: ['1.5 ລິດ', '2.5 ລິດ', '3 ລິດ', '3.5 ລິດ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຄຳຫຍໍ້ຂອງ "ມິນລີລິດ" ແມ່ນຫຍັງ? 🍼',
          options: ['ມ', 'ລ', 'ມລ', 'ຊມ'],
          correctIndex: 2,
        ),
      ];
    } else if (title.contains('ບົດທີ 12: ຮູບເລຂາຄະນິດສາມມິຕິ') && grade == 'P2') {
      questions = [
        QuizQuestion(
          questionText: 'ກະປ໋ອງນົມ ຫຼື ກະປ໋ອງນ້ຳອັດລົມ ມີຮູບຮ່າງຄ້າຍຄືຮູບສາມມິຕິໃດ? 🥫',
          options: ['ຮູບກ້ອນສາກ', 'ຮູບທໍ່ກົມ', 'ຮູບໜ່ວຍກົມ', 'ຮູບຈວຍ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ກ່ອງຂອງຂວັນ ຫຼື ກ່ອງຢາສີຟັນ ມີຮູບຮ່າງຄ້າຍຄືຮູບສາມມິຕິໃດ? 📦',
          options: ['ຮູບກ້ອນສາກ', 'ຮູບທໍ່ກົມ', 'ຮູບໜ່ວຍກົມ', 'ຮູບສາມແຈ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ໜ່ວຍບານ ⚽ ມີຮູບຮ່າງຄ້າຍຄືຮູບສາມມິຕິໃດ?',
          options: ['ຮູບກ້ອນສາກ', 'ຮູບທໍ່ກົມ', 'ຮູບໜ່ວຍກົມ', 'ຮູບຈວຍ'],
          correctIndex: 2,
        ),
      ];
    } else if (title.contains('ບົດທີ 13: ການຄິດໄລ່ຂອງ 3 ຈຳນວນ') && grade == 'P2') {
      questions = [
        QuizQuestion(
          questionText: '15 + 5 - 3 = ? 🧮',
          options: ['17', '20', '23', '15'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: '32 - 10 - 5 = ? ➖',
          options: ['22', '17', '15', '27'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: '8 + 7 + 5 = ? ➕',
          options: ['15', '18', '20', '22'],
          correctIndex: 2,
        ),
      ];
    } else if (title.contains('ບົດທີ 14: ການຈັດກຸ່ມ ແລະ ການລວບລວມຕາຕະລາງ') && grade == 'P2') {
      questions = [
        QuizQuestion(
          questionText: 'ຖ້າມີໝາກໄມ້: ສົ້ມ, ມ່ວງ, ສົ້ມ, ກ້ວຍ, ມ່ວງ, ສົ້ມ. ມີໝາກສົ້ມທັງໝົດຈັກໜ່ວຍ? 🍊',
          options: ['2 ໜ່ວຍ', '3 ໜ່ວຍ', '4 ໜ່ວຍ', '1 ໜ່ວຍ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ການນຳສະເໜີຂໍ້ມູນໃຫ້ເບິ່ງງ່າຍ ແລະ ເປັນລະບຽບຄວນໃຊ້ຫຍັງ? 📊',
          options: ['ການຂຽນລຽງກັນ', 'ຕາຕະລາງ', 'ການແຕ້ມຮູບຫຼິ້ນ', 'ບໍ່ມີຂໍ້ຖືກ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຈາກການສຳຫຼວດໝູ່ 10 ຄົນ: ມັກຮຽນເລກ 6 ຄົນ, ມັກຮຽນພາສາລາວ 4 ຄົນ. ກຸ່ມໃດໃຫຍ່ກວ່າ? 🏫',
          options: ['ກຸ່ມມັກຮຽນເລກ', 'ກຸ່ມມັກຮຽນພາສາລາວ', 'ເທົ່າກັນ', 'ບໍ່ມີຂໍ້ມູນ'],
          correctIndex: 0,
        ),
      ];
    } else if (title.contains('ບົດທີ 15: ທະນະບັດ') && grade == 'P2') {
      questions = [
        QuizQuestion(
          questionText: 'ທະນະບັດໃບ 10,000 ກີບ 1 ໃບ ແລກໃບ 5,000 ກີບ ໄດ້ຈັກໃບ? 💵',
          options: ['1 ໃບ', '2 ໃບ', '3 ໃບ', '4 ໃບ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຖ້າມີໃບ 2,000 ກີບ 3 ໃບ ຈະລວມເປັນເງິນທັງໝົດຈັກກີບ? 💵',
          options: ['4,000 ກີບ', '5,000 ກີບ', '6,000 ກີບ', '10,000 ກີບ'],
          correctIndex: 2,
        ),
        QuizQuestion(
          questionText: 'ໃບເງິນກີບລາວທີ່ມີມູນຄ່າໜ້ອຍທີ່ສຸດໃນຕົວເລືອກນີ້ແມ່ນໃບໃດ? 💵',
          options: ['ໃບ 1,000 ກີບ', 'ໃບ 5,000 ກີບ', 'ໃບ 10,000 ກີບ', 'ໃບ 2,000 ກີບ'],
          correctIndex: 0,
        ),
      ];
    } else if (title.contains('ບົດທີ 16: ການບວກ ແລະ ການລົບເລກສາມຫຼັກ') && grade == 'P2') {
      questions = [
        QuizQuestion(
          questionText: '150 + 230 = ? ➕',
          options: ['350', '380', '480', '370'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: '450 - 200 = ? ➖',
          options: ['200', '250', '300', '150'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: '300 + 700 = ? 🧮',
          options: ['900', '1000', '800', '1100'],
          correctIndex: 1,
        ),
      ];
    } else if (title.contains('ບົດທີ 17: ເສັ້ນຈຳນວນ ແລະ ຕຳແໜ່ງ') && grade == 'P2') {
      questions = [
        QuizQuestion(
          questionText: 'ຢູ່ເທິງເສັ້ນຈຳນວນ, ຈຳນວນທີ່ຢູ່ຖັດຈາກ 150 ໄປທາງຂວາ 1 ຂີດ (ຂີດລະ 10) ແມ່ນຫຍັງ? 📍',
          options: ['140', '160', '151', '200'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຈຳນວນທີ່ຢູ່ເຄິ່ງກາງລະຫວ່າງ 200 ແລະ 300 ແມ່ນຈຳນວນໃດ? 📍',
          options: ['220', '250', '280', '260'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຢູ່ເທິງເສັ້ນຈຳນວນ, ຍິ່ງໄປທາງຂວາຄ່າຂອງຈຳນວນຍິ່ງເປັນແນວໃດ? 📍',
          options: ['ຍິ່ງໜ້ອຍລົງ', 'ຍິ່ງຫຼາຍຂຶ້ນ', 'ເທົ່າເດີມ', 'ບໍ່ມີທິດທາງ'],
          correctIndex: 1,
        ),
      ];
    } else if (title.contains('ບົດທີ 18: ທວນຄືນຄະນິດສາດທ້າຍປີ') && grade == 'P2') {
      questions = [
        QuizQuestion(
          questionText: '5 x 8 = ? ✖️',
          options: ['35', '40', '45', '50'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: '350 - 150 = ? 🧮',
          options: ['100', '200', '300', '250'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຮູບສາມແຈ ມີຈັກຂ້າງ? 📐',
          options: ['2 ຂ້າງ', '3 ຂ້າງ', '4 ຂ້າງ', '5 ຂ້າງ'],
          correctIndex: 1,
        ),
      ];
    } else if (title.contains('ບົດທີ 1: ການປຽບທຽບຈຳນວນ')) {
      questions = [
        QuizQuestion(
          questionText: 'ໝາກປູມເປົ້າ 🎈 ມີ 5 ໜ່ວຍ, ສໍ້ດຳ ✏️ ມີ 3 ກ້ານ. ສິ່ງໃດມີຈຳນວນຫຼາຍກວ່າ?',
          options: ['ໝາກປູມເປົ້າ', 'ສໍ້ດຳ', 'ເທົ່າກັນ', 'ບໍ່ມີຂໍ້ຖືກ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ປຽບທຽບໝາກກ້ວຍ 🍌 2 ໜ່ວຍ ແລະ ໝາກອັບເປີ້ນ 🍎 2 ໜ່ວຍ. ຈຳນວນທັງສອງເປັນແນວໃດ?',
          options: ['ຫຼາຍກວ່າ', 'ໜ້ອຍກວ່າ', 'ເທົ່າກັນ', 'ຕ່າງກັນ'],
          correctIndex: 2,
        ),
        QuizQuestion(
          questionText: 'ປຽບທຽບຊ້າງ 🐘 ຕົວໃຫຍ່ ແລະ ແມວ 🐱 ຕົວນ້ອຍ. ສັດໂຕໃດໃຫຍ່ກວ່າ?',
          options: ['ແມວ', 'ຊ້າງ', 'ເທົ່າກັນ', 'ນ້ອຍເທົ່າກັນ'],
          correctIndex: 1,
        ),
      ];
    } else if (title.contains('ບົດທີ 2: ຈຳນວນແຕ່ 1 ເຖິງ 10 ແລະ 0')) {
      questions = [
        QuizQuestion(
          questionText: 'ນັບຈຳນວນໝາກໄມ້: 🍎 🍎 🍎 ມີຈັກໜ່ວຍ?',
          options: ['2 ໜ່ວຍ', '3 ໜ່ວຍ', '4 ໜ່ວຍ', '5 ໜ່ວຍ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຫາກບໍ່ມີຫຍັງເລີຍ ຢູ່ໃນກ່ອງ, ເຮົາຈະຂຽນແທນດ້ວຍຕົວເລກໃດ?',
          options: ['1', '2', '0', '3'],
          correctIndex: 2,
        ),
        QuizQuestion(
          questionText: 'ຕົວເລກໃດແມ່ນ \'ເລກເຈັດ\' ທີ່ຖືກຕ້ອງ?',
          options: ['5', '6', '7', '8'],
          correctIndex: 2,
        ),
      ];
    } else if (title.contains('ບົດທີ 3: ລຳດັບທີ')) {
      questions = [
        QuizQuestion(
          questionText: '🐱 (ທີ 1) -> 🐶 (ທີ 2) -> 🐰 (ທີ 3). 🐶 ຢູ່ລຳດັບທີເທົ່າໃດ?',
          options: ['ລຳດັບທີ 1', 'ລຳດັບທີ 2', 'ລຳດັບທີ 3', 'ລຳດັບສຸດທ້າຍ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ສິ່ງໃດຢູ່ \'ທາງໜ້າ\' ໝູ່ ລະຫວ່າງ: 🚗 🚲 🚶?',
          options: ['ລົດຖີບ', 'ລົດຍົນ', 'ຄົນຍ່າງ', 'ຢູ່ກາງ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ສິ່ງໃດຢູ່ \'ທາງຫຼັງ\' ໝູ່ ລະຫວ່າງ: 🚗 🚲 🚶?',
          options: ['ລົດຍົນ', 'ລົດຖີບ', 'ຄົນຍ່າງ', 'ຢູ່ໜ້າ'],
          correctIndex: 2,
        ),
      ];
    } else if (title.contains('ບົດທີ 4: ການແບ່ງຈຳນວນອອກເປັນສອງສ່ວນ')) {
      questions = [
        QuizQuestion(
          questionText: 'ຈຳນວນ 5 ແບ່ງອອກເປັນ 2 ສ່ວນ. ຫາກສ່ວນໜຶ່ງແມ່ນ 3, ອີກສ່ວນໜຶ່ງແມ່ນເທົ່າໃດ?',
          options: ['1', '2', '3', '4'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຈຳນວນ 6 ສາມາດແບ່ງເປັນ 4 ແລະ ເທົ່າໃດ?',
          options: ['1', '2', '3', '4'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຈຳນວນ 10 ສາມາດແບ່ງເປັນ 5 ແລະ ເທົ່າໃດ?',
          options: ['4', '5', '6', '7'],
          correctIndex: 1,
        ),
      ];
    } else if (title.contains('ບົດທີ 5: ການບວກ')) {
      questions = [
        QuizQuestion(
          questionText: '2 + 3 ເທົ່າກັບເທົ່າໃດ? 🍎',
          options: ['4', '5', '6', '7'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: '4 + 4 ເທົ່າກັບເທົ່າໃດ? 🧮',
          options: ['6', '7', '8', '9'],
          correctIndex: 2,
        ),
        QuizQuestion(
          questionText: '5 + 0 ເທົ່າກັບເທົ່າໃດ? 🌟',
          options: ['0', '5', '10', '6'],
          correctIndex: 1,
        ),
      ];
    } else if (title.contains('ບົດທີ 6: ການລົບ')) {
      questions = [
        QuizQuestion(
          questionText: '5 - 2 ເທົ່າກັບເທົ່າໃດ? 🍎',
          options: ['2', '3', '4', '1'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: '8 - 4 ເທົ່າກັບເທົ່າໃດ? 🧮',
          options: ['2', '3', '4', '5'],
          correctIndex: 2,
        ),
        QuizQuestion(
          questionText: '7 - 7 ເທົ່າກັບເທົ່າໃດ? 🌀',
          options: ['0', '1', '7', '14'],
          correctIndex: 0,
        ),
      ];
    } else if (title.contains('ບົດທີ 7: ຈຳນວນທີ່ຫຼາຍກວ່າ 10')) {
      questions = [
        QuizQuestion(
          questionText: '1 ຫຼັກຫົວສິບ ກັບ 5 ຫຼັກຫົວໜ່ວຍ ແມ່ນຈຳນວນໃດ?',
          options: ['10', '15', '51', '20'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ນັບຕໍ່ຈາກ 14 ໄປອີກ 1 ຈະໄດ້ຈຳນວນໃດ?',
          options: ['13', '15', '16', '12'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ເລກ 18 ຂຽນແຍກເປັນຫຼັກຫົວສິບ ແລະ ຫຼັກຫົວໜ່ວຍໄດ້ແນວໃດ?',
          options: ['10 + 8', '1 + 8', '10 + 80', '18 + 0'],
          correctIndex: 0,
        ),
      ];
    } else if (title.contains('ບົດທີ 8: ການບວກ (ຕໍ່)')) {
      questions = [
        QuizQuestion(
          questionText: '9 + 3 ເທົ່າກັບເທົ່າໃດ? 🍎',
          options: ['11', '12', '13', '14'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: '8 + 6 ເທົ່າກັບເທົ່າໃດ? 🧮',
          options: ['13', '14', '15', '16'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: '10 + 7 ເທົ່າກັບເທົ່າໃດ? 🌟',
          options: ['17', '70', '107', '16'],
          correctIndex: 0,
        ),
      ];
    } else if (title.contains('ບົດທີ 9: ການລົບ (ຕໍ່)')) {
      questions = [
        QuizQuestion(
          questionText: '12 - 3 ເທົ່າກັບເທົ່າໃດ? 🍎',
          options: ['8', '9', '10', '11'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: '15 - 7 ເທົ່າກັບເທົ່າໃດ? 🧮',
          options: ['7', '8', '9', '6'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: '18 - 10 ເທົ່າກັບເທົ່າໃດ? 🌟',
          options: ['8', '10', '18', '0'],
          correctIndex: 0,
        ),
      ];
    } else if (title.contains('ບົດທີ 10: ການຄິດໄລ່ຂອງ 3 ຈຳນວນ')) {
      questions = [
        QuizQuestion(
          questionText: '3 + 2 + 4 ເທົ່າກັບເທົ່າໃດ? 🍎',
          options: ['8', '9', '10', '7'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: '10 - 3 - 2 ເທົ່າກັບເທົ່າໃດ? 🧮',
          options: ['4', '5', '6', '7'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: '8 - 2 + 4 ເທົ່າກັບເທົ່າໃດ? 🌟',
          options: ['9', '10', '11', '8'],
          correctIndex: 1,
        ),
      ];
    } else if (title.contains('ບົດທີ 11: ການປຽບທຽບຄວາມຍາວ')) {
      questions = [
        QuizQuestion(
          questionText: 'ລະຫວ່າງ ໄມ້ດິ້ວ 🥢 ແລະ ສໍ້ດຳ ✏️. ຫາກໄມ້ດິ້ວຍາວກວ່າສໍ້ດຳ, ສິ່ງໃດສັ້ນກວ່າ?',
          options: ['ໄມ້ດິ້ວ', 'ສໍ້ດຳ', 'ຍາວເທົ່າກັນ', 'ບໍ່ມີຂໍ້ຖືກ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຫາກເຮົາຢາກຮູ້ວ່າໂຕເລກໃດຍາວກວ່າ, ເຮົາຄວນເຮັດແນວໃດ?',
          options: ['ເອົາສົ້ນເບື້ອງໜຶ່ງມາລຽນຊື່ກັນ', 'ວາງໄກໆກັນ', 'ຄາດເດົາດ້ວຍສາຍຕາ', 'ບໍ່ມີວິທີວັດ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ສາຍເຊືອກ A ຍາວ 8 ຊມ, ສາຍເຊືອກ B ຍາວ 12 ຊມ. ເຊືອກໃດຍາວກວ່າ?',
          options: ['ເຊືອກ A', 'ເຊືອກ B', 'ຍາວເທົ່າກັນ', 'ສັ້ນເທົ່າກັນ'],
          correctIndex: 1,
        ),
      ];
    } else if (title.contains('ບົດທີ 12: ຮູບຮ່າງຂອງສິ່ງຕ່າງໆທີ່ຢູ່ອ້ອມຕົວເຮົາ')) {
      questions = [
        QuizQuestion(
          questionText: 'ກ່ອງຢາຖູແຂ້ວ 📦 ມີຮູບຮ່າງໃກ້ຄຽງກັບຮູບໃດຫຼາຍທີ່ສຸດ?',
          options: ['ຮູບຊົງກະບອກ', 'ຮູບຊົງກົມ', 'ຮູບກ່ອງສີ່ຫຼັກ', 'ຮູບສາມຫຼ່ຽມ'],
          correctIndex: 2,
        ),
        QuizQuestion(
          questionText: 'ໝາກສົ້ມ 🍊 ມີຮູບຮ່າງຄ້າຍຄືກັບຮູບໃດ?',
          options: ['ຮູບຊົງກົມ', 'ຮູບຊົງກະບອກ', 'ຮູບຊົງກ້ອນ', 'ຮູບສີ່ຫຼ່ຽມ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ປ໋ອງນົມ 🥛 ມີຮູບຮ່າງຄືກັບຮູບໃດ?',
          options: ['ຮູບຊົງກົມ', 'ຮູບຊົງກະບອກ (ທໍ່ກົມ)', 'ຮູບກ່ອງ', 'ຮູບສາມຫຼ່ຽມ'],
          correctIndex: 1,
        ),
      ];
    } else if (title.contains('ບົດທີ 13: ໂມງ (ການອ່ານເວລາ)')) {
      questions = [
        QuizQuestion(
          questionText: 'ເຂັມສັ້ນຊີ້ໃສ່ເລກ 3, ເຂັມຍາວຊີ້ໃສ່ເລກ 12. ແມ່ນເວລາຈັກໂມງ?',
          options: ['12 ໂມງ', '3 ໂມງ', '6 ໂມງ', '9 ໂມງ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ໃນ 1 ວັນ ມີທັງໝົດຈັກຊົ່ວໂມງ? 📅',
          options: ['12 ຊົ່ວໂມງ', '24 ຊົ່ວໂມງ', '60 ຊົ່ວໂມງ', '10 ຊົ່ວໂມງ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ເຂັມໃດໃນໂມງທີ່ໃຊ້ບອກ \'ຊົ່ວໂມງ\'?',
          options: ['Eຂັມຍາວ', 'ເຂັມສັ້ນ', 'ເຂັມວິນາທີ', 'ທຸກເຂັມ'],
          correctIndex: 1,
        ),
      ];
    } else if (title.contains('ບົດທີ 14: ການບວກ ແລະ ການລົບ (ຕໍ່)')) {
      questions = [
        QuizQuestion(
          questionText: '13 + 5 ເທົ່າກັບເທົ່າໃດ? 🍎',
          options: ['17', '18', '19', '16'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: '17 - 4 ເທົ່າກັບເທົ່າໃດ? 🧮',
          options: ['12', '13', '14', '15'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: '20 - 5 ເທົ່າກັບເທົ່າໃດ? 🌟',
          options: ['10', '15', '16', '17'],
          correctIndex: 1,
        ),
      ];
    } else if (title.contains('ບົດທີ 15: ການປຽບທຽບປະລິມານ (ຄວາມບັນຈຸ)')) {
      questions = [
        QuizQuestion(
          questionText: 'ຂວດນ້ຳໃຫຍ່ 🍼 ແລະ ຈອກນ້ຳນ້ອຍ 🥛. ພາຊະນະໃດສາມາດບັນຈຸນ້ຳໄດ້ຫຼາຍກວ່າ?',
          options: ['ຂວດນ້ຳໃຫຍ່', 'ຈອກນ້ຳນ້ອຍ', 'ເທົ່າກັນ', 'ບໍ່ມີຂໍ້ຖືກ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຫາກເຮົາຖອກນ້ຳຈາກຈອກໃສ່ຊາມແລ້ວນ້ຳບໍ່ເຕັມຊາມ, ສິ່ງໃດໃຫຍ່ກວ່າ?',
          options: ['ຈອກ', 'ຊາມ', 'ເທົ່າກັນ', 'ບໍ່ສາມາດບອກໄດ້'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຖັງນ້ຳ A ໃສ່ນ້ຳໄດ້ 5 ລິດ, ຖັງນ້ຳ B ໃສ່ນ້ຳໄດ້ 3 ລິດ. ຖັງໃດມີຄວາມບັນຈຸຫຼາຍກວ່າ?',
          options: ['ຖັງ A', 'ຖັງ B', 'ເທົ່າກັນ', 'ສັ້ນກວ່າ'],
          correctIndex: 0,
        ),
      ];
    } else if (title.contains('ບົດທີ 16: ຮູບຮ່າງ ແລະ ການຈັດລຽງ')) {
      questions = [
        QuizQuestion(
          questionText: 'ຮູບແບບ: 🔴 🔵 🔴 🔵 🔴 ... ຮູບຕໍ່ໄປຄວນເປັນສີຫຍັງ?',
          options: ['ສີແດງ', 'ສີຟ້າ', 'ສີຂຽວ', 'ສີເຫຼືອງ'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຮູບແບບ: 🔺 🟩 🔺 🟩 ... ຮູບຕໍ່ໄປຄວນເປັນຮູບໃດ?',
          options: ['ຮູບສາມຫຼ່ຽມ', 'ຮູບສີ່ຫຼ່ຽມ', 'ຮູບວົງມົນ', 'ຮູບຫ້າຫຼ່ຽມ'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ຮູບແບບ: 1, 2, 1, 2, 1, ... ຕົວເລກຕໍ່ໄປແມ່ນເລກໃດ?',
          options: ['1', '2', '3', '0'],
          correctIndex: 1,
        ),
      ];
    } else if (title.contains('ບົດທີ 17: ຈຳນວນທີ່ຫຼາຍກວ່າ 20')) {
      questions = [
        QuizQuestion(
          questionText: '2 ຫຼັກຫົວສິບ ກັບ 4 ຫຼັກຫົວໜ່ວຍ ແມ່ນຈຳນວນໃດ?',
          options: ['20', '24', '42', '204'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ເລກ 35 ຂຽນແຍກເປັນຫຼັກຫົວສິບ ແລະ ຫຼັກຫົວໜ່ວຍໄດ້ແນວໃດ?',
          options: ['30 + 5', '3 + 5', '30 + 50', '35 + 0'],
          correctIndex: 0,
        ),
        QuizQuestion(
          questionText: 'ນັບເພີ່ມເທື່ອລະ 10: 10, 20, 30, ... ຈຳນວນຕໍ່ໄປແມ່ນຫຍັງ?',
          options: ['35', '40', '50', '100'],
          correctIndex: 1,
        ),
      ];
    } else if (title.contains('ບົດທີ 18: ເລກລາວ')) {
      questions = [
        QuizQuestion(
          questionText: 'ຕົວເລກລາວ \'໕\' ກົງກັບເລກອາຣັບໃດ?',
          options: ['3', '4', '5', '6'],
          correctIndex: 2,
        ),
        QuizQuestion(
          questionText: 'ຕົວເລກລາວ \'໑໐\' ແມ່ນເລກໃດ?',
          options: ['1', '10', '5', '0'],
          correctIndex: 1,
        ),
        QuizQuestion(
          questionText: 'ຕົວເລກລາວ \'໓\' ກົງກັບເລກອາຣັບໃດ?',
          options: ['2', '3', '4', '5'],
          correctIndex: 1,
        ),
      ];
    } else if (title.contains('ໂຈດອ່ານ 9') || title.contains('ສະຫຼະພິເສດ')) {
      questions = [
        QuizQuestion(questionText: 'ລຳ ໃຊ້ສະຫຼະໃດ?', options: ['ໄx', 'ໃx', 'xຳ', 'xົ'], correctIndex: 2),
        QuizQuestion(questionText: 'ສະຫຼະ ໄx ແລະ ໃx ອອກສຽງ...?', options: ['... ສຽງດຽວກັນ', '... ສຽງຍາວ', '... ສຽງສັ້ນ', 'ຕ່າງກັນ'], correctIndex: 0),
        QuizQuestion(questionText: 'ມົດ ໃຊ້ສະຫຼະໃດ?', options: ['xຳ', 'xົ', 'xົວ', 'ເxຍ'], correctIndex: 1),
        QuizQuestion(questionText: 'ເຮືອ ໃຊ້ສະຫຼະໃດ?', options: ['ເxຍ', 'ເxືອ', 'xົວ', 'ໃx'], correctIndex: 1),
        QuizQuestion(questionText: 'ເຢຍ ໃຊ້ສະຫຼະໃດ?', options: ['... ໃຊ້ສະຫຼະ ເxຍ', '... ໃຊ້ສະຫຼະ ເxືອ', '... ໃຊ້ສະຫຼະ ໄx', '... ໃຊ້ສະຫຼະ xຳ'], correctIndex: 0),
      ];
    } else {
      // Fallback questions if any custom lesson is added
      if (subject == 'ຄະນິດສາດ') {
        questions = [
          QuizQuestion(
            questionText: '2 + 2 = ? 🍎',
            options: ['3', '4', '5', '6'],
            correctIndex: 1,
          ),
          QuizQuestion(
            questionText: '10 - 5 = ? 🧮',
            options: ['4', '5', '6', '7'],
            correctIndex: 1,
          ),
          QuizQuestion(
            questionText: 'ຈຳນວນໃດຫຼາຍກວ່າລະຫວ່າງ 8 ແລະ 5? ⚖️',
            options: ['5', '8', 'ເທົ່າກັນ', 'ບໍ່ມີຂໍ້ຖືກ'],
            correctIndex: 1,
          ),
        ];
      } else {
        if (grade == 'P2') {
          questions = [
            QuizQuestion(
              questionText: 'ຄຳໃດແມ່ນ "ຄຳນາມ" (ຊື່ເອີ້ນສິ່ງຂອງ)? 🎒',
              options: ['ປຶ້ມ', 'ແລ່ນ', 'ງາມ', 'ໄວ'],
              correctIndex: 0,
            ),
            QuizQuestion(
              questionText: 'ຄຳໃດສະກົດດ້ວຍ "ຕົວສະກົດ ງ" ໄດ້ຖືກຕ້ອງ? 🔔',
              options: ['ຮຽນ', 'ແກງ', 'ບາດ', 'ອາບ'],
              correctIndex: 1,
            ),
            QuizQuestion(
              questionText: 'ຄຳວ່າ "ແມວ" 🐱 ປະກອບດ້ວຍຕົວສະກົດໃດ?',
              options: ['ຕົວສະກົດ ງ', 'ຕົວສະກົດ ວ', 'ຕົວສະກົດ ມ', 'ຕົວສະກົດ ກ'],
              correctIndex: 1,
            ),
          ];
        } else {
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
    if (showFeedback && isAnswerCorrect) return; // Already answered correctly
    if (_failedOptionIndices.contains(index)) return; // Already tapped incorrect option

    setState(() {
      final isCorrect = index == questions[currentQuestionIndex].correctIndex;

      if (isCorrect) {
        selectedOptionIndex = index;
        showFeedback = true;
        isAnswerCorrect = true;
        if (!_hadMistake) {
          score++;
        }
        _playCorrectSound();
      } else {
        selectedOptionIndex = index;
        isAnswerCorrect = false;
        _hadMistake = true;
        _failedOptionIndices.add(index);
        _playIncorrectSound();
      }
    });
  }

  void _nextQuestion() async {
    try {
    } catch (_) {}
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        selectedOptionIndex = -1;
        showFeedback = false;
        isAnswerCorrect = false;
        _failedOptionIndices.clear();
        _hadMistake = false;
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
                // Reading Mode Body: Premium Practice Card and Next Button
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),
                      // Premium practice instruction card
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryPink.withValues(alpha: 0.1),
                              blurRadius: 30,
                              spreadRadius: 2,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF1F8E9), // Light green background
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.campaign_rounded, // megaphone/practice icon
                                size: 48,
                                color: Color(0xFF4CAF50),
                              ),
                            ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
                            const SizedBox(height: 24),
                            const Text(
                              'ຝຶກອ່ານອອກສຽງໃຫ້ດັງໆເດີ້!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF333333),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'ອ່ານຕົວອັກສອນ ຫຼື ຄຳສັບຂ້າງເທິງນີ້ ແລ້ວຄລິກປຸ່ມສີຂຽວທາງລຸ່ມ',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF666666),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0),
                      const Spacer(),
                      // Next/Completed Button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF38B264), // Premium green
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 4,
                            ),
                            onPressed: () {
                              _playCorrectSound();
                              _nextQuestion();
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  currentQuestionIndex < questions.length - 1
                                      ? 'ອ່ານແລ້ວ! ໄປຕໍ່ ➡️'
                                      : 'ອ່ານແລ້ວ! ສຳເລັດ 🎓',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).animate().scale(delay: 200.ms, duration: 400.ms),
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
                    children: List.generate(currentQuestion.options.length, (index) {
                      final isCorrectOption = index == currentQuestion.correctIndex;
                      final isFailedOption = _failedOptionIndices.contains(index);

                      Color cardColor = Colors.white;
                      Color textColor = AppTheme.textColor;
                      BorderSide border = BorderSide(color: Colors.grey.shade200, width: 1.5);

                      if (isFailedOption) {
                        cardColor = const Color(0xFFFFEBEE);
                        textColor = const Color(0xFFC62828);
                        border = const BorderSide(color: Color(0xFFE57373), width: 2.5);
                      } else if (showFeedback && selectedOptionIndex == index) {
                        if (isCorrectOption) {
                          cardColor = const Color(0xFFE8F5E9);
                          textColor = const Color(0xFF2E7D32);
                          border = const BorderSide(color: Color(0xFF81C784), width: 2.5);
                        } else {
                          cardColor = const Color(0xFFFFEBEE);
                          textColor = const Color(0xFFC62828);
                          border = const BorderSide(color: Color(0xFFE57373), width: 2.5);
                        }
                      } else if (showFeedback && isCorrectOption) {
                        cardColor = const Color(0xFFE8F5E9);
                        textColor = const Color(0xFF2E7D32);
                        border = const BorderSide(color: Color(0xFF81C784), width: 2.5);
                      }

                      return GestureDetector(
                        onTap: () => _checkAnswer(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.fromBorderSide(border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              currentQuestion.options[index],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ),
                        ).animate(target: isFailedOption ? 1 : 0)
                         .shake(hz: 5, duration: 300.ms),
                      );
                    }),
                  ),
                ),
                if (showFeedback && isAnswerCorrect) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 4,
                      ),
                      onPressed: _nextQuestion,
                      child: Text(
                        currentQuestionIndex < questions.length - 1
                            ? 'ຕໍ່ໄປ ➡️'
                            : 'ສຳເລັດແລ້ວ! 🎓',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.3, end: 0),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}


