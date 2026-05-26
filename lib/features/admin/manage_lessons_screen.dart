import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/database/db_helper.dart';
import '../../core/models/lesson.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ManageLessonsScreen extends StatefulWidget {
  const ManageLessonsScreen({super.key});

  @override
  State<ManageLessonsScreen> createState() => _ManageLessonsScreenState();
}

class _ManageLessonsScreenState extends State<ManageLessonsScreen> {
  List<Lesson> lessons = [];
  List<String> subjects = []; // Dynamic unique subjects
  bool isLoading = true;

  // Filter States
  String selectedGrade = 'All'; // 'All', 'P1', 'P2'
  String selectedSubject = 'All'; // 'All', 'Lao', 'Math'

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  Future<void> _loadLessons() async {
    final data = await DatabaseHelper.instance.getAllLessons();
    final uniqueSubjects = await DatabaseHelper.instance.getAllUniqueSubjects();
    setState(() {
      lessons = data;
      subjects = uniqueSubjects;
      isLoading = false;
    });
  }

  String _getSubjectLabel(String subject) {
    if (subject == 'Lao' || subject == 'ພາສາລາວ') return 'ພາສາລາວ';
    if (subject == 'Math' || subject == 'ຄະນິດສາດ') return 'ຄະນິດສາດ';
    return subject;
  }

  Future<void> _deleteLesson(int id) async {
    await DatabaseHelper.instance.deleteLesson(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ລຶບບົດຮຽນສຳເລັດແລ້ວ!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    _loadLessons();
  }

  void _showDeleteConfirmation(BuildContext context, Lesson lesson) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.red.shade400,
                size: 28,
              ),
              const SizedBox(width: 10),
              const Text(
                'ຢືນຢັນການລຶບ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            'ທ່ານຕ້ອງການລຶບບົດຮຽນ "${lesson.title}" ແທ້ບໍ່?\n(ການດຳເນີນການນີ້ບໍ່ສາມາດກູ້ຄືນໄດ້)',
            style: const TextStyle(fontSize: 16),
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'ຍົກເລີກ',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteLesson(lesson.id!);
              },
              child: const Text(
                'ລຶບເລີຍ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter the loaded lessons list
    final filteredLessons = lessons.where((lesson) {
      final matchesGrade =
          selectedGrade == 'All' || lesson.grade == selectedGrade;
      final matchesSubject =
          selectedSubject == 'All' || lesson.subject == selectedSubject;
      return matchesGrade && matchesSubject;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'ຈັດການບົດຮຽນ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF3E8EF7),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter Cards Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Grade Filter Row
                Row(
                  children: [
                    const Text(
                      'ຊັ້ນຮຽນ:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.textColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip(
                              label: 'ທັງໝົດ',
                              isSelected: selectedGrade == 'All',
                              onSelected: () =>
                                  setState(() => selectedGrade = 'All'),
                            ),
                            _buildFilterChip(
                              label: 'ປ.1',
                              isSelected: selectedGrade == 'P1',
                              onSelected: () =>
                                  setState(() => selectedGrade = 'P1'),
                            ),
                            _buildFilterChip(
                              label: 'ປ.2',
                              isSelected: selectedGrade == 'P2',
                              onSelected: () =>
                                  setState(() => selectedGrade = 'P2'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Subject Filter Row
                Row(
                  children: [
                    const Text(
                      'ວິຊາຮຽນ:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.textColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip(
                              label: 'ທັງໝົດ',
                              isSelected: selectedSubject == 'All',
                              onSelected: () =>
                                  setState(() => selectedSubject = 'All'),
                            ),
                            ...subjects.map((sub) => _buildFilterChip(
                                  label: _getSubjectLabel(sub),
                                  isSelected: selectedSubject == sub,
                                  onSelected: () =>
                                      setState(() => selectedSubject = sub),
                                )),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Result Status Banner
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ລາຍການບົດຮຽນ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3E8EF7).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'ພົບ ${filteredLessons.length} ບົດຮຽນ',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3E8EF7),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main List / Empty State Builder
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredLessons.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    itemCount: filteredLessons.length,
                    itemBuilder: (context, index) {
                      final lesson = filteredLessons[index];
                      final isLao = lesson.subject == 'Lao';

                      return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(
                                color: Colors.grey.shade100,
                                width: 1.5,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  // Left Colored Subject Icon Container
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isLao
                                          ? const Color(0xFFFFEBEE)
                                          : const Color(0xFFE8F5E9),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(
                                      isLao
                                          ? Icons.menu_book_rounded
                                          : Icons.calculate_rounded,
                                      size: 32,
                                      color: isLao
                                          ? AppTheme.primaryPink
                                          : AppTheme.primaryGreen,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  // Text & Badge columns
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Badges Row
                                        Row(
                                          children: [
                                            _buildBadge(
                                              text: lesson.grade == 'P1'
                                                  ? 'ປ.1'
                                                  : 'ປ.2',
                                              color: const Color(0xFF3E8EF7),
                                            ),
                                            const SizedBox(width: 6),
                                            _buildBadge(
                                              text: isLao
                                                  ? 'ພາສາລາວ'
                                                  : 'ຄະນິດສາດ',
                                              color: isLao
                                                  ? AppTheme.primaryPink
                                                  : AppTheme.primaryGreen,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        // Title
                                        Text(
                                          lesson.title,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textColor,
                                            height: 1.2,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        // Stars row
                                        Row(
                                          children: [
                                            const Text(
                                              'ລາງວັນ: ',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Row(
                                              children: List.generate(
                                                lesson.totalStars,
                                                (i) => const Icon(
                                                  Icons.star_rounded,
                                                  color: Color(0xFFF59E0B),
                                                  size: 18,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Deletion Actions
                                  IconButton(
                                    icon: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.delete_rounded,
                                        color: Colors.red.shade400,
                                        size: 20,
                                      ),
                                    ),
                                    onPressed: () => _showDeleteConfirmation(
                                      context,
                                      lesson,
                                    ),
                                    tooltip: 'ລຶບບົດຮຽນ',
                                  ),
                                ],
                              ),
                            ),
                          )
                          .animate()
                          .fade(duration: 350.ms)
                          .slideY(begin: 0.08, end: 0);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton:
          FloatingActionButton.extended(
            backgroundColor: const Color(0xFF38B264),
            onPressed: () async {
              await context.push('/admin/lessons/add');
              _loadLessons();
            },
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'ເພີ່ມບົດຮຽນ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ).animate().scale(
            delay: 200.ms,
            duration: 400.ms,
            curve: Curves.easeOutBack,
          ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        selected: isSelected,
        onSelected: (_) => onSelected(),
        selectedColor: const Color(0xFF3E8EF7),
        backgroundColor: Colors.grey.shade100,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
    );
  }

  Widget _buildBadge({required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.library_books_rounded,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'ບໍ່ພົບບົດຮຽນ',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'ຍັງບໍ່ມີບົດຮຽນໃນໝວດໝູ່ນີ້,\nກະລຸນາກົດປຸ່ມເພີ່ມບົດຮຽນດ້ານລຸ່ມເພື່ອເພີ່ມບົດຮຽນໃໝ່.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
            ],
          ).animate().fade(duration: 400.ms).scale(begin: const Offset(0.9, 0.9)),
        ),
      ),
    );
  }
}
