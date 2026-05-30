import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/database/db_helper.dart';
import '../../core/models/user_profile.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/avatar_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ManageProgressScreen extends StatefulWidget {
  const ManageProgressScreen({super.key});

  @override
  State<ManageProgressScreen> createState() => _ManageProgressScreenState();
}

class _ManageProgressScreenState extends State<ManageProgressScreen> {
  List<UserProfile> students = [];
  bool isLoading = true;
  String searchQuery = '';
  UserProfile? selectedStudent;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    final users = await DatabaseHelper.instance.readAllUsers();
    setState(() {
      students = users;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredStudents = students.where((student) {
      final nameMatch = student.name.toLowerCase().contains(searchQuery.toLowerCase());
      final phoneMatch = student.phone.contains(searchQuery);
      return nameMatch || phoneMatch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'ຕິດຕາມຜົນການຮຽນ',
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search Bar Section
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: TextField(
                    onChanged: (val) => setState(() => searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'ຄົ້ນຫາຊື່ຜູ້ຫຼິ້ນ ຫຼື ເບີໂທຜູ້ປົກຄອງ...',
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF3E8EF7)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF3E8EF7), width: 1.5),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),

                // Student List
                Expanded(
                  child: filteredStudents.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredStudents.length,
                          itemBuilder: (context, index) {
                            final student = filteredStudents[index];
                            final isSelected = selectedStudent?.id == student.id;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF3E8EF7) : Colors.grey.shade100,
                                  width: isSelected ? 2 : 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: CircleAvatar(
                                  radius: 28,
                                  backgroundColor: AvatarHelper.getColor(student.avatarId).withValues(alpha: 0.18),
                                  child: Text(
                                    AvatarHelper.getEmoji(student.avatarId),
                                    style: const TextStyle(fontSize: 30),
                                  ),
                                ),
                                title: Text(
                                  student.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textColor,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      'ເບີໂທ: ${student.phone}',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 18),
                                        const SizedBox(width: 4),
                                        Text(
                                          'ຄະແນນລວມ: ${student.score} ດາວ',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFF59E0B),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: ElevatedButton.icon(
                                  onPressed: () async {
                                    await _showProgressDetailsSheet(context, student);
                                    _loadStudents(); // Reload main scores when returning
                                  },
                                  icon: const Icon(Icons.analytics_rounded, size: 16, color: Colors.white),
                                  label: const Text(
                                    'ເບິ່ງຜົນ',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3E8EF7),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                ),
                              ),
                            ).animate().fade(duration: 300.ms, delay: (index * 50).ms).slideY(begin: 0.05, end: 0);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Future<void> _showProgressDetailsSheet(BuildContext context, UserProfile student) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _ProgressDetailsSheet(student: student);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_alt_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'ບໍ່ພົບຜູ້ຫຼິ້ນໃນລະບົບ',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _ProgressDetailsSheet extends StatefulWidget {
  final UserProfile student;
  const _ProgressDetailsSheet({required this.student});

  @override
  State<_ProgressDetailsSheet> createState() => _ProgressDetailsSheetState();
}

class _ProgressDetailsSheetState extends State<_ProgressDetailsSheet> {
  List<Map<String, dynamic>> detailedProgress = [];
  bool isProgressLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetailedProgress();
  }

  Future<void> _loadDetailedProgress() async {
    final progress = await DatabaseHelper.instance.getUserProgressDetailed(widget.student.id!);
    if (mounted) {
      setState(() {
        detailedProgress = progress;
        isProgressLoading = false;
      });
    }
  }

  Future<void> _resetProgress(int lessonId) async {
    await DatabaseHelper.instance.resetUserProgress(widget.student.id!, lessonId);
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ຣີເຊັດຄວາມຄືບໜ້າບົດຮຽນສຳເລັດແລ້ວ!'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Refresh progress locally inside sheet
    await _loadDetailedProgress();
  }

  String _getSubjectLabel(String subject) {
    if (subject == 'Lao' || subject == 'ພາສາລາວ' || subject == 'ການອ່ານ') return 'ພາສາລາວ';
    if (subject == 'Math' || subject == 'ຄະນິດສາດ') return 'ຄະນິດສາດ';
    return subject;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFFF5F7FB),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          // Drag handle & Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AvatarHelper.getColor(widget.student.avatarId).withValues(alpha: 0.18),
                      child: Text(
                        AvatarHelper.getEmoji(widget.student.avatarId),
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ລາຍງານຜົນຮຽນຂອງ ${widget.student.name}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ເບີໂທຜູ້ປົກຄອງ: ${widget.student.phone}',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, color: Color(0xFF3E8EF7)),
                      tooltip: 'ແກ້ໄຂໂປຣໄຟລ໌',
                      onPressed: () async {
                        final navigator = Navigator.of(context);
                        final updated = await context.push('/edit-profile?userId=${widget.student.id}');
                        if (updated == true && mounted) {
                          navigator.pop(); // Close sheet to reload list!
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Progress List
          Expanded(
            child: isProgressLoading
                ? const Center(child: CircularProgressIndicator())
                : detailedProgress.isEmpty
                    ? const Center(child: Text('ບໍ່ມີຂໍ້ມູນຄວາມຄືບໜ້າການຮຽນ'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: detailedProgress.length,
                        itemBuilder: (context, idx) {
                          final prog = detailedProgress[idx];
                          final starsEarned = prog['stars_earned'] ?? 0;
                          final subject = prog['subject'] ?? '';
                          final grade = prog['grade'] ?? '';
                          final title = prog['title'] ?? '';
                          final maxStars = prog['max_stars'] ?? 3;
                          final lessonId = prog['lesson_id'];
                          final isLao = subject == 'Lao' || subject == 'ພາສາລາວ' || subject == 'ການອ່ານ';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.shade100, width: 1.5),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  // Subject Icon indicator
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isLao ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                      isLao ? Icons.menu_book_rounded : Icons.calculate_rounded,
                                      size: 24,
                                      color: isLao ? AppTheme.primaryPink : AppTheme.primaryGreen,
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  // Content Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            _buildBadge(
                                              text: grade == 'P1' ? 'ປ.1' : 'ປ.2',
                                              color: const Color(0xFF3E8EF7),
                                            ),
                                            const SizedBox(width: 6),
                                            _buildBadge(
                                              text: _getSubjectLabel(subject),
                                              color: isLao ? AppTheme.primaryPink : AppTheme.primaryGreen,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          title,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textColor,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Text(
                                              starsEarned == 3
                                                  ? 'ຜ່ານແລ້ວ: '
                                                  : starsEarned > 0
                                                      ? 'ຍັງບໍ່ຜ່ານ: '
                                                      : 'ຍັງບໍ່ທັນຮຽນ',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: starsEarned == 3
                                                    ? Colors.green.shade600
                                                    : starsEarned > 0
                                                        ? Colors.amber.shade700
                                                        : Colors.grey.shade500,
                                              ),
                                            ),
                                            if (starsEarned > 0)
                                              Row(
                                                children: List.generate(
                                                  maxStars,
                                                  (starIdx) => Icon(
                                                    Icons.star_rounded,
                                                    color: starIdx < starsEarned
                                                        ? const Color(0xFFF59E0B)
                                                        : Colors.grey.shade300,
                                                    size: 16,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Actions
                                  if (starsEarned > 0)
                                    IconButton(
                                      icon: Icon(Icons.restart_alt_rounded, color: Colors.orange.shade600),
                                      tooltip: 'ຣີເຊັດຄວາມຄືບໜ້າ',
                                      onPressed: () => _resetProgress(lessonId),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
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
          fontSize: 10,
        ),
      ),
    );
  }
}
