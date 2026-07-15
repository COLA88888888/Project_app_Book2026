import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/database/db_helper.dart';
import '../../core/models/lesson.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/lesson_questions.dart';

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
    final rawList = LessonQuestions.getQuestions(grade, subject, title);
    if (rawList.isNotEmpty) {
      questions = rawList.map((q) {
        return QuizQuestion(
          questionText: q['questionText'] as String,
          options: List<String>.from(q['options'] as List),
          correctIndex: q['correctIndex'] as int,
          readingGuide: q['readingGuide'] as String?,
        );
      }).toList();
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


